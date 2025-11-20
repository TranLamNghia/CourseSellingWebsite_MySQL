using System.Security.Claims;
using CloudinaryDotNet;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApplication1.Areas.Student.Services;
using WebApplication1.Areas.Student.ViewModel;
using WebApplication1.Models;
using WebApplication1.Models.VNPay;
using WebApplication1.Services;

namespace WebApplication1.Areas.Student.Controllers
{
    [Area("Student")]
    [Authorize(Roles = "Student")]
    public class CartController : Controller
    {

        private readonly AppDbContext _context;
        private readonly ILogger<AccountController> _logger;
        private readonly Cloudinary _cloudinary;
        private readonly ICartStudent _cartService;
        private readonly IVNPayService _vnPayService;

        public CartController(AppDbContext context, ILogger<AccountController> logger, Cloudinary cloudinary, ICartStudent cartStudent, IVNPayService vnPayService)
        {
            _context = context;
            _logger = logger;
            _cloudinary = cloudinary;
            _cartService = cartStudent;
            _vnPayService = vnPayService;
        }

        [HttpGet]
        [Route("/student/mycart")]
        public async Task<IActionResult> MyCart()
        {
            var maHocSinh = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            var gioHang = await _context.GioHangs
                .FirstOrDefaultAsync(gh => gh.MaHocSinh == maHocSinh);

            var chiTietGioHangs = await _context.ChiTietGioHangs
                .Where(ctgh => ctgh.MaGioHang == gioHang.MaGioHang)
                .Include(ctgh => ctgh.MaKhoaHocNavigation)
                    .ThenInclude(kh => kh.MaGiaoVienNavigation)
                .ToListAsync();

            int totalItems = chiTietGioHangs.Count;
            decimal totalPrice = chiTietGioHangs.Sum(ctgh => ctgh.MaKhoaHocNavigation.GiaKhoaHoc);

            var viewModel = new MyCartViewModel
            {
                MaGioHang = gioHang.MaGioHang,
                CartItems = chiTietGioHangs.Select(ctgh => ctgh.MaKhoaHocNavigation).ToList(),
                TotalItems = totalItems,
                TotalPrice = totalPrice
            };

            return View(viewModel);
        }

        [HttpPost]
        [Route("/student/mycart/requestpaymentvnpay")]
        public async Task<IActionResult> RequestPaymentVNPay(PaymentInformationModel model)
        {
            var maHocSinh = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            var gioHang = await _context.GioHangs
                    .Include(gh => gh.ChiTietGioHangs)
                    .ThenInclude(ctgh => ctgh.MaKhoaHocNavigation)
                    .FirstOrDefaultAsync(gh => gh.MaHocSinh == maHocSinh);
            if (gioHang == null || !gioHang.ChiTietGioHangs.Any())
            {
                _logger.LogWarning("No cart or empty cart found for user: {UserId}", maHocSinh);
                return Json(new { success = false, message = "Giỏ hàng trống hoặc không tồn tại." }, StatusCodes.Status400BadRequest);
            }

            var paymentUrl = _vnPayService.CreatePaymentUrl(model, HttpContext);

            if (string.IsNullOrEmpty(paymentUrl))
            {
                _logger.LogError("Failed to create VNPay payment URL.");
                TempData["ErrorMessage"] = "Không thể tạo yêu cầu thanh toán.";
                return RedirectToAction("MyCart");
            }
            _logger.LogInformation("Redirecting to VNPay payment URL: {PaymentUrl}", paymentUrl);
            return Json(new { success = true, paymentUrl });
        }

        [HttpGet]
        [Route("/student/mycart/PaymentCallbackVnpay")]
        public async Task<IActionResult> PaymentCallbackVnpay()
        {
            try
            {
                var response = _vnPayService.PaymentExecute(Request.Query);

                if (response == null)
                {
                    _logger.LogWarning("PaymentExecute trả về phản hồi null cho truy vấn: {@Query}", Request.Query);
                    TempData["ErrorMessage"] = "Không nhận được dữ liệu thanh toán hợp lệ.";
                    return RedirectToAction("MyCart", "Cart");
                }

                if (!response.Success || response.VnPayResponseCode != "00")
                {
                    _logger.LogWarning("Thanh toán thất bại hoặc phản hồi không hợp lệ từ VNPay. Phản hồi: {@Response}", response);
                    TempData["ErrorMessage"] = response.Message ?? "Thanh toán thất bại.";
                    return RedirectToAction("MyCart", "Cart");
                }

                _logger.LogInformation("Thanh toán VNPay thành công. Phản hồi: {@Response}", response);

                // Lấy userId
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    _logger.LogWarning("Không tìm thấy người dùng đã xác thực trong PaymentCallbackVnpay.");
                    TempData["ErrorMessage"] = "Người dùng không được xác thực.";
                    return RedirectToAction("MyCart", "Cart");
                }

                // Tạo PaymentInformationModel
                double amount;
                try
                {
                    amount = response.OrderDescription != null
                        ? double.Parse(response.OrderDescription.Split(' ').Last())
                        : 0;
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Không thể phân tích Amount từ OrderDescription: {OrderDescription}", response.OrderDescription);
                    amount = 0; // Số tiền mặc định nếu phân tích thất bại
                }

                var model = new PaymentInformationModel
                {
                    Name = User.Identity?.Name ?? "Unknown",
                    Amount = amount,
                    OrderDescription = response.OrderDescription ?? "Thanh toán qua VnPay tại EduLearn",
                    OrderType = "course", // Giả định OrderType luôn là 'course'
                };

                // Gọi ProcessCartToMyLearning
                bool success = await ProcessCartToMyLearning(userId, model);

                if (success)
                {
                    return RedirectToAction("MyLearning", "Account", new { area = "Student", message = "Thanh toán thành công!" }); // Chỉ định rõ area và controller
                }
                else
                {
                    return RedirectToAction("MyCart", "Cart");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi trong PaymentCallbackVnpay. Truy vấn: {@Query}", Request.Query);
                TempData["ErrorMessage"] = "Lỗi xử lý thanh toán: " + ex.Message;
                return RedirectToAction("MyCart", "Cart");
            }
        }

        private async Task<bool> ProcessCartToMyLearning(string userId, PaymentInformationModel model)
        {
            var gioHang = await _context.GioHangs
                .Include(gh => gh.ChiTietGioHangs)
                    .ThenInclude(ctgh => ctgh.MaKhoaHocNavigation)
                .FirstOrDefaultAsync(gh => gh.MaHocSinh == userId);

            if (gioHang == null || !gioHang.ChiTietGioHangs.Any())
            {
                _logger.LogWarning("Không tìm thấy giỏ hàng hoặc giỏ hàng trống cho người dùng: {UserId}", userId);
                TempData["ErrorMessage"] = "Giỏ hàng trống hoặc không tồn tại.";
                return false;
            }

            foreach (var chiTiet in gioHang.ChiTietGioHangs)
            {
                var khoaHocHocSinh = new KhoaHocHocSinh
                {
                    MaHocSinh = userId,
                    MaKhoaHoc = chiTiet.MaKhoaHoc,
                    NgayDangKy = DateTime.Now
                };
                _context.KhoaHocHocSinhs.Add(khoaHocHocSinh);
                _context.ChiTietGioHangs.Remove(chiTiet);
            }

            await _context.SaveChangesAsync();
            return true;
        }
    

        [HttpPost]
        [Route("/student/addtocart")]
        public async Task<IActionResult> AddToCart(string maKhoaHoc)
        {
            try
            {
                var maHocSinh = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
                var gioHang = await _context.GioHangs
                    .FirstOrDefaultAsync(gh => gh.MaHocSinh == maHocSinh);

                await _cartService.AddCourse(gioHang.MaGioHang, maKhoaHoc);

                return Json(new { success = true, message = "Thêm khóa học vào giỏ hàng thành công." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in AddToCart for MaKhoaHoc: {MaKhoaHoc}", maKhoaHoc);
                return Json(new { success = false, message = ex.Message }, StatusCodes.Status500InternalServerError);
            }
        }

        [HttpDelete]
        [Route("/student/removefromcart")]
        public async Task<IActionResult> RemoveFromCart(string maKhoaHoc)
        {
            try
            {
                var maHocSinh = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (string.IsNullOrEmpty(maHocSinh))
                {
                    _logger.LogWarning("User not authenticated for DELETE request.");
                    return Json(new { success = false, message = "Vui lòng đăng nhập để thực hiện hành động này." }, StatusCodes.Status401Unauthorized);
                }

                var gioHang = await _context.GioHangs
                    .FirstOrDefaultAsync(gh => gh.MaHocSinh == maHocSinh);

                if (gioHang == null)
                {
                    _logger.LogWarning("Cart not found for MaHocSinh: {MaHocSinh}", maHocSinh);
                    return Json(new { success = false, message = "Giỏ hàng không tồn tại." }, StatusCodes.Status404NotFound);
                }

                _logger.LogInformation("Attempting to delete course {MaKhoaHoc} from cart {MaGioHang}", maKhoaHoc, gioHang.MaGioHang);
                await _cartService.DeleteCourse(gioHang.MaGioHang, maKhoaHoc);
                _logger.LogInformation("Course {MaKhoaHoc} deleted successfully from cart {MaGioHang}", maKhoaHoc, gioHang.MaGioHang);

                return Json(new { success = true, message = "Xóa khóa học thành công." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting course {MaKhoaHoc}: {Message}", maKhoaHoc, ex.Message);
                return Json(new { success = false, message = "Lỗi server: " + ex.Message }, StatusCodes.Status500InternalServerError);
            }
        }
    }
}
