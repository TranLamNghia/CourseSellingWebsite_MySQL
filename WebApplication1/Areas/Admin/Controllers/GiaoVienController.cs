//using Microsoft.AspNetCore.Mvc;
//using Microsoft.EntityFrameworkCore;
//using WebApplication1.Models;

//namespace WebApplication1.Controllers
//{
//    public class GiaoViensController : Controller
//    {
//        private readonly AppDbContext _context;

//        public GiaoViensController(AppDbContext context)
//        {
//            _context = context;
//        }

//        // GET: GiaoViens
//        public async Task<IActionResult> Index()
//        {
//            return View(await _context.GiaoViens.ToListAsync());
//        }

//        // GET: GiaoViens/Details/5
//        public async Task<IActionResult> Details(string id)
//        {
//            if (id == null) return NotFound();

//            var giaoVien = await _context.GiaoViens
//                .FirstOrDefaultAsync(m => m.MaGiaoVien == id);
//            if (giaoVien == null) return NotFound();

//            return View(giaoVien);
//        }

//        // GET: GiaoViens/Create
//        public IActionResult Create()
//        {
//            return View();
//        }

//        // POST: GiaoViens/Create
//        [HttpPost]
//        [ValidateAntiForgeryToken]
//        public async Task<IActionResult> Create([Bind("MaGiaoVien,HoTen,DuongDanAnhDaiDien,Email,DienThoai,GioiThieu,NgayTao")] GiaoVien giaoVien)
//        {
//            if (ModelState.IsValid)
//            {
//                _context.Add(giaoVien);
//                await _context.SaveChangesAsync();
//                return RedirectToAction(nameof(Index));
//            }
//            return View(giaoVien);
//        }

//        // GET: GiaoViens/Edit/5
//        public async Task<IActionResult> Edit(string id)
//        {
//            if (id == null) return NotFound();

//            var giaoVien = await _context.GiaoViens.FindAsync(id);
//            if (giaoVien == null) return NotFound();

//            return View(giaoVien);
//        }

//        // POST: GiaoViens/Edit/5
//        [HttpPost]
//        [ValidateAntiForgeryToken]
//        public async Task<IActionResult> Edit(string id, [Bind("MaGiaoVien,HoTen,DuongDanAnhDaiDien,Email,DienThoai,GioiThieu,NgayTao")] GiaoVien giaoVien)
//        {
//            if (id != giaoVien.MaGiaoVien) return NotFound();

//            if (ModelState.IsValid)
//            {
//                try
//                {
//                    _context.Update(giaoVien);
//                    await _context.SaveChangesAsync();
//                }
//                catch (DbUpdateConcurrencyException)
//                {
//                    if (!_context.GiaoViens.Any(e => e.MaGiaoVien == id))
//                        return NotFound();
//                    else
//                        throw;
//                }
//                return RedirectToAction(nameof(Index));
//            }
//            return View(giaoVien);
//        }

//        // GET: GiaoViens/Delete/5
//        public async Task<IActionResult> Delete(string id)
//        {
//            if (id == null) return NotFound();

//            var giaoVien = await _context.GiaoViens
//                .FirstOrDefaultAsync(m => m.MaGiaoVien == id);
//            if (giaoVien == null) return NotFound();

//            return View(giaoVien);
//        }

//        // POST: GiaoViens/Delete/5
//        [HttpPost, ActionName("Delete")]
//        [ValidateAntiForgeryToken]
//        public async Task<IActionResult> DeleteConfirmed(string id)
//        {
//            var giaoVien = await _context.GiaoViens.FindAsync(id);
//            if (giaoVien != null)
//            {
//                _context.GiaoViens.Remove(giaoVien);
//                await _context.SaveChangesAsync();
//            }

//            return RedirectToAction(nameof(Index));
//        }
//    }
//}
