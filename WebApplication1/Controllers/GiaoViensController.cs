using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApplication1.Models;
using WebApplication1.Services;

namespace WebApplication1.Controllers
{
    public class GiaoViensController : Controller
    {
        private readonly AppDbContext _context;
        private readonly CloudinaryService _cloudinaryService;

        public GiaoViensController(AppDbContext context, CloudinaryService cloudinaryService)
        {
            _context = context;
            _cloudinaryService = cloudinaryService;
        }

        // GET: GiaoViens
        public async Task<IActionResult> Index()
        {
            return View(await _context.GiaoViens.ToListAsync());
        }

        // GET: GiaoViens/Details/5
        public async Task<IActionResult> Details(string id)
        {
            if (id == null) return NotFound();

            var giaoVien = await _context.GiaoViens.FirstOrDefaultAsync(m => m.MaGiaoVien == id);
            if (giaoVien == null) return NotFound();

            return View(giaoVien);
        }

        // GET: GiaoViens/Create
        public IActionResult Create()
        {
            return View();
        }

        // POST: GiaoViens/Create
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create([Bind("MaGiaoVien,HoTen,Email,DienThoai,GioiThieu,NgayTao")] GiaoVien giaoVien, IFormFile AnhDaiDien)
        {

            if (AnhDaiDien != null)
            {
                var imageUrl = _cloudinaryService.UploadImage(AnhDaiDien);
                giaoVien.DuongDanAnhDaiDien = imageUrl;
            }

            if (ModelState.IsValid)
            {
                _context.Add(giaoVien);
                await _context.SaveChangesAsync();
                return RedirectToAction(nameof(Index));
            }
            return View(giaoVien);
        }

        // GET: GiaoViens/Edit/5
        public async Task<IActionResult> Edit(string id)
        {
            if (id == null) return NotFound();

            var giaoVien = await _context.GiaoViens.FindAsync(id);
            if (giaoVien == null) return NotFound();

            return View(giaoVien);
        }

        // POST: GiaoViens/Edit/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(string id, [Bind("MaGiaoVien,HoTen,Email,DienThoai,GioiThieu")] GiaoVien giaoVien, IFormFile? AnhDaiDien)
        {
            if (id != giaoVien.MaGiaoVien)
            {
                return NotFound();
            }

            // Lấy thông tin cũ từ database
            var giaoVienCu = await _context.GiaoViens.FindAsync(id);
            if (giaoVienCu == null)
            {
                return NotFound();
            }

            // Nếu có ảnh đại diện mới
            if (AnhDaiDien != null && AnhDaiDien.Length > 0)
            {
                // Gọi dịch vụ Cloudinary để upload ảnh
                var imageUrl = await _cloudinaryService.UploadImageAsync(AnhDaiDien);
                giaoVienCu.DuongDanAnhDaiDien = imageUrl;
            }

            // Cập nhật các trường còn lại
            giaoVienCu.HoTen = giaoVien.HoTen;
            giaoVienCu.Email = giaoVien.Email;
            giaoVienCu.DienThoai = giaoVien.DienThoai;
            giaoVienCu.GioiThieu = giaoVien.GioiThieu;

            if (ModelState.IsValid)
            {
                try
                {
                    _context.Update(giaoVienCu);
                    await _context.SaveChangesAsync();
                    return RedirectToAction(nameof(Index));
                }
                catch (DbUpdateConcurrencyException)
                {
                    if (!GiaoVienExists(giaoVien.MaGiaoVien))
                    {
                        return NotFound();
                    }
                    else
                    {
                        throw;
                    }
                }
            }

            return View(giaoVienCu);
        }

        private bool GiaoVienExists(string id)
        {
            return _context.GiaoViens.Any(e => e.MaGiaoVien == id);
        }


        // GET: GiaoViens/Delete/5
        public async Task<IActionResult> Delete(string id)
        {
            if (id == null) return NotFound();

            var giaoVien = await _context.GiaoViens.FirstOrDefaultAsync(m => m.MaGiaoVien == id);
            if (giaoVien == null) return NotFound();

            return View(giaoVien);
        }

        // POST: GiaoViens/Delete/5
        [HttpPost, ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteConfirmed(string id)
        {
            var giaoVien = await _context.GiaoViens.FindAsync(id);
            if (giaoVien != null)
            {
                _context.GiaoViens.Remove(giaoVien);
                await _context.SaveChangesAsync();
            }

            return RedirectToAction(nameof(Index));
        }
    }
}
