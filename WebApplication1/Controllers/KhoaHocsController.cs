using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Primitives;
using WebApplication1.Models;
using WebApplication1.Services;

namespace WebApplication1.Controllers
{
    public class KhoaHocsController : Controller
    {
        private readonly AppDbContext _context;
        private readonly CloudinaryService _cloudinaryService;
        public KhoaHocsController(AppDbContext context, CloudinaryService cloudinaryService)
        {
            _context = context;
            _cloudinaryService = cloudinaryService;
        }

        // GET: KhoaHocs
        public async Task<IActionResult> Index(string sortOrder, string searchString, string teacherName)
        {
            var appDbContext = _context.KhoaHocs.Include(k => k.MaGiaoVienNavigation);
            ViewData["CurrentSort"] = sortOrder;
            ViewData["NameSortParm"] = String.IsNullOrEmpty(sortOrder) ? "name_desc" : "";
            ViewData["DateSortParm"] = sortOrder == "date_asc" ? "date_desc" : "date_asc";
            ViewData["PriceSortParm"] = sortOrder == "price_asc" ? "price_desc" : "price_asc";
            ViewData["TeacherSortParm"] = sortOrder == "teacher_asc" ? "teacher_desc" : "teacher_asc";
            // Lưu lại các giá trị lọc hiện tại
            ViewData["CurrentFilter"] = searchString;
            ViewData["TeacherFilter"] = teacherName;

            // 2. Lấy dữ liệu khóa học từ database
            // Dùng AsQueryable() để có thể xây dựng câu truy vấn từng bước
            var courses = _context.KhoaHocs.Include(k => k.MaGiaoVienNavigation).AsQueryable();

            // 3. Áp dụng bộ lọc (Filter) nếu có
            if (!String.IsNullOrEmpty(searchString))
            {
                courses = courses.Where(s => s.TieuDe.Contains(searchString));
            }

            if (!String.IsNullOrEmpty(teacherName))
            {
                // Lọc theo tên giáo viên thông qua thuộc tính điều hướng
                courses = courses.Where(c => c.MaGiaoVienNavigation.HoTen.Contains(teacherName));
            }

            // 4. Áp dụng sắp xếp (Sort) dựa vào tham số sortOrder
            switch (sortOrder)
            {
                case "name_desc":
                    courses = courses.OrderByDescending(s => s.TieuDe);
                    break;
                case "date_asc":
                    courses = courses.OrderBy(s => s.NgayCapNhat);
                    break;
                case "date_desc":
                    courses = courses.OrderByDescending(s => s.NgayCapNhat);
                    break;
                case "price_asc":
                    courses = courses.OrderBy(s => s.GiaKhoaHoc);
                    break;
                case "price_desc":
                    courses = courses.OrderByDescending(s => s.GiaKhoaHoc);
                    break;
                case "teacher_asc":
                    courses = courses.OrderBy(s => s.MaGiaoVien);
                    break;
                case "teacher_desc":
                    courses = courses.OrderByDescending(s => s.MaGiaoVien);
                    break;
                default: // Mặc định sắp xếp theo tên A-Z
                    courses = courses.OrderBy(s => s.TieuDe);
                    break;
            }

            // 5. Trả về View với danh sách đã được lọc và sắp xếp
            return View(await courses.ToListAsync());
        }

        // GET: KhoaHocs/Details/5
        public async Task<IActionResult> Details(string id)
        {
            if (id == null)
            {
                return NotFound();
            }

            var khoaHoc = await _context.KhoaHocs
                .Include(k => k.MaGiaoVienNavigation)
                .FirstOrDefaultAsync(m => m.MaKhoaHoc == id);
            if (khoaHoc == null)
            {
                return NotFound();
            }

            return View(khoaHoc);
        }

        // GET: KhoaHocs/Create
        public IActionResult Create()

        {
            ViewData["MaMonHoc"] = new SelectList(_context.MonHocs, "MaMonHoc", "TenMonHoc");
            ViewData["MaGiaoVien"] = new SelectList(_context.GiaoViens, "MaGiaoVien", "HoTen");
            return View();
        }

        // POST: KhoaHocs/Create
        // To protect from overposting attacks, enable the specific properties you want to bind to.
        // For more details, see http://go.microsoft.com/fwlink/?LinkId=317598.
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create([Bind("MaMonHoc,TieuDe,DuongDanAnhKhoaHoc,MoTa,ThoiHan,MaGiaoVien, GiaKhoaHoc")] KhoaHoc khoaHoc, IFormFile AnhKhoaHoc)
        {
            khoaHoc.NgayCapNhat = DateTime.Now;

            if (Request.Form.TryGetValue("GiaKhoaHoc", out StringValues giaValueString) &&
                decimal.TryParse(giaValueString, NumberStyles.Any, CultureInfo.InvariantCulture, out decimal giaKhoaHocValue))
            {
                khoaHoc.GiaKhoaHoc = giaKhoaHocValue;
            }

            var mh = await _context.MonHocs.FindAsync(khoaHoc.MaMonHoc);
            if (mh != null)
            {
                khoaHoc.MonHoc = mh.TenMonHoc;
            }

            if (AnhKhoaHoc != null)
            {
                var imageUrl = _cloudinaryService.UploadImage(AnhKhoaHoc);
                khoaHoc.DuongDanAnhKhoaHoc = imageUrl;
            }

            khoaHoc.MaKhoaHoc = "BH" + DateTime.Now.ToString("yyMMddHHmmss") + new Random().Next(100, 999);

            ModelState.Remove(nameof(KhoaHoc.MaGiaoVienNavigation));
            ModelState.Remove(nameof(KhoaHoc.MaMonHocNavigation));
            ModelState.Remove(nameof(KhoaHoc.MonHoc));
            ModelState.Remove(nameof(KhoaHoc.NgayCapNhat));
            ModelState.Remove("MaKhoaHoc");
            if (ModelState.IsValid)
            {
                _context.Add(khoaHoc);
                await _context.SaveChangesAsync();
                return RedirectToAction(nameof(Index));
            }

            ViewData["MaGiaoVien"] = new SelectList(_context.GiaoViens, "MaGiaoVien", "HoTen", khoaHoc.MaGiaoVien);
            ViewData["MaMonHoc"] = new SelectList(_context.MonHocs, "MaMonHoc", "TenMonHoc", khoaHoc.MaMonHoc);
            return View(khoaHoc);
        }

        // GET: KhoaHocs/Edit/5
        public async Task<IActionResult> Edit(string id)
        {
            if (id == null) return NotFound();

            var khoaHoc = await _context.KhoaHocs.FindAsync(id);
            if (khoaHoc == null) return NotFound();

            // Thêm danh sách Môn học và Giáo viên (Hiển thị tên)
            ViewData["MaMonHoc"] = new SelectList(_context.MonHocs, "MaMonHoc", "TenMonHoc", khoaHoc.MaMonHoc);
            ViewData["MaGiaoVien"] = new SelectList(_context.GiaoViens, "MaGiaoVien", "HoTen", khoaHoc.MaGiaoVien);

            return View(khoaHoc);
        }

        // POST: KhoaHocs/Edit/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(string id,
    [Bind("MaKhoaHoc,MaMonHoc,TieuDe,MoTa,GiaKhoaHoc,ThoiHan,MaGiaoVien")] KhoaHoc khoaHoc,
    IFormFile? AnhKhoaHoc)
        {
            if (id != khoaHoc.MaKhoaHoc) return NotFound();

            var khoaHocToUpdate = await _context.KhoaHocs.FindAsync(id);
            if (khoaHocToUpdate == null) return NotFound();

            // Xóa validation cho các property navigation và cột string MonHoc cũ
            ModelState.Remove(nameof(KhoaHoc.MaGiaoVienNavigation));
            ModelState.Remove(nameof(KhoaHoc.MaMonHocNavigation));
            ModelState.Remove("MonHoc");

            if (ModelState.IsValid)
            {
                // 1. Cập nhật ảnh nếu có file mới
                if (AnhKhoaHoc != null && AnhKhoaHoc.Length > 0)
                {
                    var imageUrl = await _cloudinaryService.UploadImageAsync(AnhKhoaHoc);
                    khoaHocToUpdate.DuongDanAnhKhoaHoc = imageUrl;
                }

                // 2. Cập nhật thông tin từ form
                khoaHocToUpdate.MaMonHoc = khoaHoc.MaMonHoc;
                khoaHocToUpdate.TieuDe = khoaHoc.TieuDe;
                khoaHocToUpdate.MoTa = khoaHoc.MoTa;
                khoaHocToUpdate.GiaKhoaHoc = khoaHoc.GiaKhoaHoc;
                khoaHocToUpdate.ThoiHan = khoaHoc.ThoiHan;
                khoaHocToUpdate.MaGiaoVien = khoaHoc.MaGiaoVien;
                khoaHocToUpdate.NgayCapNhat = DateTime.Now;

                // 3. Đồng bộ tên môn học vào cột 'MonHoc' (nếu database yêu cầu)
                var mh = await _context.MonHocs.FindAsync(khoaHoc.MaMonHoc);
                if (mh != null) khoaHocToUpdate.MonHoc = mh.TenMonHoc;

                try
                {
                    _context.Update(khoaHocToUpdate);
                    await _context.SaveChangesAsync();
                    return RedirectToAction(nameof(Index));
                }
                catch (DbUpdateConcurrencyException)
                {
                    if (!KhoaHocExists(khoaHoc.MaKhoaHoc)) return NotFound();
                    else throw;
                }
            }

            // Nếu lỗi, load lại dữ liệu cho Dropdown
            ViewData["MaMonHoc"] = new SelectList(_context.MonHocs, "MaMonHoc", "TenMonHoc", khoaHoc.MaMonHoc);
            ViewData["MaGiaoVien"] = new SelectList(_context.GiaoViens, "MaGiaoVien", "HoTen", khoaHoc.MaGiaoVien);
            return View(khoaHocToUpdate);
        }


        // GET: KhoaHocs/Delete/5
        public async Task<IActionResult> Delete(string id)
        {
            if (id == null)
            {
                return NotFound();
            }

            var khoaHoc = await _context.KhoaHocs
                .Include(k => k.MaGiaoVienNavigation)
                .FirstOrDefaultAsync(m => m.MaKhoaHoc == id);
            if (khoaHoc == null)
            {
                return NotFound();
            }

            return View(khoaHoc);
        }

        // POST: KhoaHocs/Delete/5
        [HttpPost, ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteConfirmed(string id)
        {
            var khoaHoc = await _context.KhoaHocs.FindAsync(id);
            if (khoaHoc != null)
            {
                _context.KhoaHocs.Remove(khoaHoc);
            }

            await _context.SaveChangesAsync();
            return RedirectToAction(nameof(Index));
        }

        private bool KhoaHocExists(string id)
        {
            return _context.KhoaHocs.Any(e => e.MaKhoaHoc == id);
        }
    }
}