using Microsoft.AspNetCore.Http; 
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Identity;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using WebApplication1.Models;
using WebApplication1.Services;

namespace WebApplication1.Controllers
{
    public class HocSinhsController : Controller
    {
        private readonly AppDbContext _context;
        private readonly CloudinaryService _cloudinaryService;
        private readonly PasswordHasher<object> _passwordHasher;

        public HocSinhsController(AppDbContext context, CloudinaryService cloudinaryService)
        {
            _context = context;
            _cloudinaryService = cloudinaryService;
            _passwordHasher = new PasswordHasher<object>();
        }

        public async Task<IActionResult> Index()
        {
            return View(await _context.HocSinhs.ToListAsync());
        }

        public async Task<IActionResult> Details(string id)
        {
            if (id == null) return NotFound();
            var hocSinh = await _context.HocSinhs.FirstOrDefaultAsync(m => m.MaHocSinh == id);
            if (hocSinh == null) return NotFound();
            return View(hocSinh);
        }

        public IActionResult Create() => View();

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create([Bind("HoTen,PassHash,Email,DienThoai,NgaySinh,GioiTinh,DiaChi, IsActive")] HocSinh hocSinh, IFormFile? AnhDaiDien)
        {

            if (string.IsNullOrEmpty(hocSinh.PassHash))
            {
                ModelState.AddModelError("PassHash", "Mật khẩu không được để trống!");
            }

            if (string.IsNullOrWhiteSpace(hocSinh.DienThoai))
            {
                ModelState.AddModelError("DienThoai", "Số điện thoại là bắt buộc và không được để trống.");
            }
            else if (_context.HocSinhs.Any(h => h.DienThoai == hocSinh.DienThoai))
            {
                ModelState.AddModelError("DienThoai", "Số điện thoại này đã tồn tại trong hệ thống.");
            }

            if (!string.IsNullOrEmpty(hocSinh.Email) && _context.HocSinhs.Any(h => h.Email == hocSinh.Email))
            {
                ModelState.AddModelError("Email", "Email này đã được sử dụng bởi một học sinh khác.");
            }
            hocSinh.MaHocSinh = "HS" + DateTime.Now.ToString("yyMMddHHmmss");
            hocSinh.NgayDangKy = DateTime.Now;
            if (AnhDaiDien != null)
            {
                var imageUrl = _cloudinaryService.UploadImage(AnhDaiDien);
                hocSinh.DuongDanAnhDaiDien = imageUrl;
            }

            ModelState.Remove(nameof(hocSinh.MaHocSinh));
            ModelState.Remove(nameof(hocSinh.DuongDanAnhDaiDien));

            if (ModelState.IsValid)
            {
                _context.Add(hocSinh);
                await _context.SaveChangesAsync();
                return RedirectToAction(nameof(Index));
            }
            return View(hocSinh);
        }

        public async Task<IActionResult> Edit(string id)
        {
            if (id == null) return NotFound();
            var hocSinh = await _context.HocSinhs.FindAsync(id);
            if (hocSinh == null) return NotFound();
            return View(hocSinh);
        }
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(string id, [Bind("MaHocSinh,HoTen,Email,DienThoai,NgaySinh,GioiTinh,DiaChi, IsActive")] HocSinh hocSinh, IFormFile? AnhDaiDien)
        {
            if (id != hocSinh.MaHocSinh) return NotFound();

            var hocSinhCu = await _context.HocSinhs.FindAsync(id);
            if (hocSinhCu == null) return NotFound();

            ModelState.Remove("PassHash");
            ModelState.Remove("NgayDangKy");
            if (ModelState.IsValid)
            {
                try
                {
                    if (AnhDaiDien != null && AnhDaiDien.Length > 0)
                    {
                        var imageUrl = await _cloudinaryService.UploadImageAsync(AnhDaiDien);
                        if (!string.IsNullOrEmpty(imageUrl))
                        {
                            hocSinhCu.DuongDanAnhDaiDien = imageUrl;
                        }
                    }
                    hocSinhCu.IsActive = hocSinh.IsActive;
                    hocSinhCu.HoTen = hocSinh.HoTen;
                    hocSinhCu.Email = hocSinh.Email;
                    hocSinhCu.DienThoai = hocSinh.DienThoai;
                    hocSinhCu.NgaySinh = hocSinh.NgaySinh;
                    hocSinhCu.GioiTinh = hocSinh.GioiTinh;
                    hocSinhCu.DiaChi = hocSinh.DiaChi;

                    _context.Update(hocSinhCu);
                    await _context.SaveChangesAsync();

                    return RedirectToAction(nameof(Index));
                }
                catch (DbUpdateConcurrencyException)
                {
                    if (!_context.HocSinhs.Any(e => e.MaHocSinh == hocSinh.MaHocSinh)) return NotFound();
                    else throw;
                }
            }

            var errors = ModelState.Values.SelectMany(v => v.Errors);
            foreach (var error in errors)
            {
                Console.WriteLine("Validation Error: " + error.ErrorMessage);
            }

            return View(hocSinhCu);
        }

        private bool HocSinhExists(string id) => _context.HocSinhs.Any(e => e.MaHocSinh == id);
    }
}