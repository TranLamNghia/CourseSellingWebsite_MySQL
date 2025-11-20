using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Security.Claims;
using System.Threading.Tasks;
using WebApplication1.Models;
using WebApplication1.Models.VNPay;
using WebApplication1.Services;

namespace WebApplication1.Areas.Student.Controllers
{
    [Area("Student")]
    [Authorize(Roles = "Student")]
    public class AccountController : Controller
    {
        private readonly ILogger<AccountController> _logger;
        private readonly AppDbContext _context;
        private readonly CloudinaryService _cloudinaryService;
        private readonly IVNPayService _vnPayService;

        public AccountController(ILogger<AccountController> logger, AppDbContext context, CloudinaryService cloudinaryService, IVNPayService vnPayService)
        {
            _logger = logger;
            _context = context;
            _cloudinaryService = cloudinaryService;
            _vnPayService = vnPayService;
        }

        [HttpGet]
        [Route("/student/mylearning")]
        public IActionResult MyLearning()
        {
            var maHocSinh = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(maHocSinh))
            {
                return RedirectToAction("Login", "Account", new { area = "" });
            }

            var featuredCourses = _context.KhoaHocHocSinhs
                .Where(khhs => khhs.MaHocSinh == maHocSinh)
                .Include(khhs => khhs.MaKhoaHocNavigation)
                .ThenInclude(kh => kh.MaGiaoVienNavigation)
                .Select(khhs => khhs.MaKhoaHocNavigation)
                .ToList();

            var viewModel = new
            {
                FeaturedCourses = featuredCourses ?? new List<KhoaHoc>()
            };
            return View(viewModel);
        }

        [HttpGet]
        [Route("/student/profile")]
        public IActionResult Profile()
        {
            var maHocSinh = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(maHocSinh))
            {
                return RedirectToAction("Login", "Account", new { area = "" });
            }

            var hocSinh = _context.HocSinhs
                .FirstOrDefault(hs => hs.MaHocSinh == maHocSinh);

            if (hocSinh == null)
            {
                return NotFound("Không tìm thấy thông tin học sinh.");
            }

            return View(hocSinh);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        [Route("/student/profile")]
        public async Task<IActionResult> Profile(HocSinh model, IFormFile AvatarFile)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var hocSinh = await _context.HocSinhs
                .FirstOrDefaultAsync(h => h.MaHocSinh == userId);

            if (hocSinh == null)
            {
                _logger.LogWarning("HocSinh not found for userId: {UserId}", userId);
                return Json(new { success = false, message = "Không tìm thấy thông tin học sinh" });
            }

            
            if (!string.IsNullOrEmpty(model.HoTen))
            {
                hocSinh.HoTen = model.HoTen;
            }
            if (!string.IsNullOrEmpty(model.Email))
            {
                hocSinh.Email = model.Email;
            }
            if (!string.IsNullOrEmpty(model.DienThoai))
            {
                hocSinh.DienThoai = model.DienThoai;
            }
            if (model.NgaySinh.HasValue)
            {
                hocSinh.NgaySinh = model.NgaySinh;
            }
            if (!string.IsNullOrEmpty(model.GioiTinh))
            {
                hocSinh.GioiTinh = model.GioiTinh;
            }
            if (!string.IsNullOrEmpty(model.DiaChi))
            {
                hocSinh.DiaChi = model.DiaChi;
            }

            // Xử lý tải lên ảnh đại diện nếu có file
            if (AvatarFile != null && AvatarFile.Length > 0)
            {
                if (AvatarFile.Length > 5 * 1024 * 1024)
                {
                    return Json(new { success = false, message = "Kích thước file không được vượt quá 5MB" });
                }

                try
                {
                    var avatarUrl = await _cloudinaryService.UploadFileAsync(AvatarFile, CloudinaryService.UploadType.Avatar);
                    hocSinh.DuongDanAnhDaiDien = avatarUrl;
                    _logger.LogInformation("Avatar uploaded successfully. URL: {Url}", avatarUrl);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Lỗi khi tải ảnh lên Cloudinary.");
                    return Json(new { success = false, message = $"Lỗi khi tải ảnh lên: {ex.Message}" });
                }
            }
            else if (string.IsNullOrEmpty(model.DuongDanAnhDaiDien))
            {
                hocSinh.DuongDanAnhDaiDien = null;
            }

            try
            {
                _context.Update(hocSinh);
                await _context.SaveChangesAsync();
                _logger.LogInformation("Profile updated successfully for MaHocSinh: {MaHocSinh}", hocSinh.MaHocSinh);
                return Json(new
                {
                    success = true,
                    message = "Cập nhật thông tin thành công",
                    hoTen = hocSinh.HoTen,
                    maHocSinh = hocSinh.MaHocSinh
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi cập nhật thông tin hồ sơ học sinh.");
                return Json(new { success = false, message = $"Lỗi khi lưu thông tin: {ex.Message}" });
            }
        }
    }
}