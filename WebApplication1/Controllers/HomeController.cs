using System.Diagnostics;
using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApplication1.Models;
using WebApplication1.ViewModels;

namespace WebApplication1.Controllers
{
    public class HomeController : Controller
    {
        private readonly ILogger<HomeController> _logger;
        private readonly AppDbContext _context;
        private readonly PasswordHasher<object> _passwordHasher;

        public HomeController(ILogger<HomeController> logger, AppDbContext context)
        {
            _logger = logger;
            _context = context;
            _passwordHasher = new PasswordHasher<object>();
        }

        [HttpGet]
        [Route("/homepage")]
        public IActionResult HomePage()
        {
            var featuredCourses = _context.KhoaHocs
                .Include(k => k.MaGiaoVienNavigation)
                .Take(6)
                .ToList();

            var subjects = _context.KhoaHocs
                .GroupBy(k => k.MonHoc)
                .Select(g => new { Subject = g.Key, Count = g.Count() })
                .ToList();

            var viewModel = new
            {
                FeaturedCourses = featuredCourses,
                Subjects = subjects
            };

            return View(viewModel);
        }

        [HttpGet]
        [Route("/signup")]
        public IActionResult SignUp()
        {
            return View(new RegisterVM());
        }

        [HttpPost]
        [Route("/signup")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SignUp(RegisterVM model)
        {
            _logger.LogInformation("Received UserType: {UserType}", model.UserType);
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            // Kiểm tra và gán giá trị cho HoTen
            if (string.IsNullOrWhiteSpace(model.LastName) || string.IsNullOrWhiteSpace(model.FirstName))
            {
                ModelState.AddModelError("", "Họ và Tên không được để trống.");
                return View(model);
            }

            // Kiểm tra UserType
            if (string.IsNullOrWhiteSpace(model.UserType))
            {
                ModelState.AddModelError("UserType", "Vui lòng chọn loại người dùng (Học Sinh hoặc Admin).");
                return View(model);
            }

            if (model.UserType == "student")
            {
                // Kiểm tra số điện thoại và email đã tồn tại trong bảng HocSinh
                if (await _context.HocSinhs.AnyAsync(h => h.DienThoai == model.DienThoai))
                {
                    ModelState.AddModelError("", "Số điện thoại đã được đăng ký cho học sinh.");
                    return View(model);
                }

                if (await _context.HocSinhs.AnyAsync(h => h.Email == model.Email))
                {
                    ModelState.AddModelError("", "Email đã được đăng ký cho học sinh.");
                    return View(model);
                }

                // Tạo đối tượng HocSinh, để MaHocSinh là null để trigger tự tạo
                var hocSinh = new HocSinh
                {
                    MaHocSinh = "temp",
                    DienThoai = model.DienThoai,
                    HoTen = model.HoTen,
                    Email = model.Email,
                    PassHash = _passwordHasher.HashPassword(null, model.Password),
                    NgayDangKy = DateTime.Now
                };
                Console.Write("hocsinh", hocSinh.PassHash);
                await _context.HocSinhs.AddAsync(hocSinh);
                await _context.SaveChangesAsync();

                var savedHocSinh = await _context.HocSinhs
                    .FirstOrDefaultAsync(h => h.Email == hocSinh.Email && h.DienThoai == hocSinh.DienThoai);

                if (savedHocSinh == null)
                {
                    ModelState.AddModelError("", "Đã xảy ra lỗi khi lưu thông tin sinh viên.");
                    return View(model);
                }

                // Đăng nhập ngay sau khi đăng ký
                var claims = new List<Claim>
                {
                    new Claim(ClaimTypes.Name, model.HoTen ?? model.DienThoai),
                    new Claim(ClaimTypes.NameIdentifier, savedHocSinh.MaHocSinh), // Sử dụng giá trị từ savedHocSinh
                    new Claim(ClaimTypes.Role, "Student")
                };

                var claimsIdentity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
                var authProperties = new AuthenticationProperties
                {
                    IsPersistent = false,
                    ExpiresUtc = DateTimeOffset.UtcNow.AddMinutes(30)
                };

                await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, new ClaimsPrincipal(claimsIdentity), authProperties);

                return RedirectToAction("HomePage", "Home", new { area = "Student" });
            }
            else if (model.UserType == "admin")
            {
                // ... (giữ nguyên phần cho Admin)
            }

            ModelState.AddModelError("", "Loại người dùng không hợp lệ.");
            return View(model);
        }

        [HttpGet]
        [HttpGet]
        [Route("/signin")]
        public IActionResult SignIn()
        {
            return View(new LoginVM());
        }

        [HttpPost]
        [Route("/signin")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SignIn(LoginVM model)
        {
            _logger.LogInformation("Received UserType: {UserType}", model.UserType);
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            if (string.IsNullOrWhiteSpace(model.UserType))
            {
                ModelState.AddModelError("UserType", "Vui lòng chọn loại người dùng (Học Sinh hoặc Admin).");
                return View(model);
            }

            if (model.UserType == "student")
            {
                // Kiểm tra trong bảng HocSinh
                var hocSinh = await _context.HocSinhs.FirstOrDefaultAsync(h => h.DienThoai == model.DienThoai);
                if (hocSinh == null)
                {
                    ModelState.AddModelError("", "Số điện thoại không tồn tại trong danh sách học sinh.");
                    return View(model);
                }

                // Kiểm tra mật khẩu
                var verificationResult = _passwordHasher.VerifyHashedPassword(null, hocSinh.PassHash, model.Password);
                if (verificationResult != PasswordVerificationResult.Success)
                {
                    ModelState.AddModelError("", "Mật khẩu không đúng.");
                    return View(model);
                }

                // Đăng nhập
                var claims = new List<Claim>
                {
                    new Claim(ClaimTypes.Name, hocSinh.HoTen ?? hocSinh.DienThoai),
                    new Claim(ClaimTypes.NameIdentifier, hocSinh.MaHocSinh),
                    new Claim(ClaimTypes.Role, "Student")
                };

                var claimsIdentity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
                var authProperties = new AuthenticationProperties
                {
                    IsPersistent = model.RememberMe,
                    ExpiresUtc = DateTimeOffset.UtcNow.AddMinutes(30)
                };

                await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, new ClaimsPrincipal(claimsIdentity), authProperties);

                return RedirectToAction("HomePage", "Home", new { area = "Student" });
            }
            else if (model.UserType == "admin")
            {
                // Kiểm tra trong bảng Admin
                var admin = await _context.Admins.FirstOrDefaultAsync(a => a.DienThoai == model.DienThoai);
                if (admin == null)
                {
                    ModelState.AddModelError("", "Số điện thoại không tồn tại trong danh sách admin.");
                    return View(model);
                }

                // Kiểm tra mật khẩu
                var verificationResult = _passwordHasher.VerifyHashedPassword(null, admin.PassHash, model.Password);
                if (verificationResult != PasswordVerificationResult.Success)
                {
                    ModelState.AddModelError("", "Mật khẩu không đúng.");
                    return View(model);
                }

                // Đăng nhập
                var claims = new List<Claim>
                {
                    new Claim(ClaimTypes.Name, admin.HoTen ?? admin.DienThoai),
                    new Claim(ClaimTypes.NameIdentifier, admin.MaAdmin),
                    new Claim(ClaimTypes.Role, "Admin")
                };

                var claimsIdentity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
                var authProperties = new AuthenticationProperties
                {
                    IsPersistent = model.RememberMe,
                    ExpiresUtc = DateTimeOffset.UtcNow.AddMinutes(30)
                };

                await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, new ClaimsPrincipal(claimsIdentity), authProperties);

                return RedirectToAction("Dashboard", "Admin", new { area = "Admin" });
            }

            ModelState.AddModelError("", "Loại người dùng không hợp lệ.");
            return View(model);
        }

        [HttpGet]
        [Route("/signout")]
        public async Task<IActionResult> SignOut()
        {
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            return RedirectToAction("SignIn", "Home");
        }

        public IActionResult Privacy()
        {
            return View();
        }

        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }
    }
}