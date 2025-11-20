using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApplication1.Models;
using WebApplication1.ViewModel; // Namespace của ViewModel
using WebApplication1.Services; // Namespace của CloudinaryService
using System;
using System.Linq;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Globalization; // Cho CultureInfo
using Microsoft.Extensions.Primitives; // Cho StringValues

public class BaiHocsController : Controller
{
    private readonly AppDbContext _context;
    private readonly CloudinaryService _cloudinaryService; // Inject CloudinaryService

    public BaiHocsController(AppDbContext context, CloudinaryService cloudinaryService)
    {
        _context = context;
        _cloudinaryService = cloudinaryService;
    }
    // GET: BaiHocs/Index?maKhoaHoc=KHXXX
    public async Task<IActionResult> Index(string maKhoaHoc)
    {
        if (string.IsNullOrEmpty(maKhoaHoc))
        {
            return BadRequest("Vui lòng cung cấp mã khóa học.");
        }

        var khoaHoc = await _context.KhoaHocs
                                    .Include(kh => kh.BaiHocs.OrderBy(bh => bh.ThuTu))
                                    .FirstOrDefaultAsync(kh => kh.MaKhoaHoc == maKhoaHoc);

        var baiHocDauTien = khoaHoc.BaiHocs.FirstOrDefault();

        var viewModel = new ChiTietKhoaHocViewModel
        {
            MaKhoaHoc = khoaHoc.MaKhoaHoc,
            TieuDeKhoaHoc = khoaHoc.TieuDe,
            DanhSachBaiHoc = khoaHoc.BaiHocs.Select(bh => new BaiHocViewModel
            {
                MaBaiHoc = bh.MaBaiHoc,
                TieuDe = bh.TieuDe ?? "N/A",
                ThuTu = bh.ThuTu,
                LinkVideo = bh.LinkVideo
            }).ToList(),
            LinkVideoBanDau = baiHocDauTien?.LinkVideo,
            TieuDeBaiHocBanDau = baiHocDauTien?.TieuDe ?? (khoaHoc.BaiHocs.Any() ? "N/A" : "Chưa có bài học")
        };

        if (viewModel.DanhSachBaiHoc == null || !viewModel.DanhSachBaiHoc.Any())
        {
            viewModel.LinkVideoBanDau = "#";
        }

        ViewData["Title"] = $"Bài học: {khoaHoc.TieuDe}";
        return View(viewModel);
    }
    // GET: BaiHocs/Create?maKhoaHoc=VALUE
    public async Task<IActionResult> Create(string maKhoaHoc)
    {
        if (string.IsNullOrEmpty(maKhoaHoc))
        {
            return BadRequest("Mã khóa học là bắt buộc để tạo bài học.");
        }
        var khoaHoc = await _context.KhoaHocs.FindAsync(maKhoaHoc);
        if (khoaHoc == null)
        {
            return NotFound($"Khóa học với mã '{maKhoaHoc}' không tồn tại.");
        }

        int thuTuMoi = 1;
        var baiHocCuoi = await _context.BaiHocs
                                .Where(bh => bh.MaKhoaHoc == maKhoaHoc)
                                .OrderByDescending(bh => bh.ThuTu)
                                .FirstOrDefaultAsync();
        if (baiHocCuoi != null)
        {
            thuTuMoi = baiHocCuoi.ThuTu + 1;
        }

        var baiHocMoi = new BaiHoc
        {
            MaKhoaHoc = maKhoaHoc,
            ThuTu = thuTuMoi
            // Các trường khác sẽ được nhập từ form
        };

        ViewBag.TenKhoaHoc = khoaHoc.TieuDe;
        return View(baiHocMoi);
    }

    // POST: BaiHocs/Create
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(
        [Bind("MaKhoaHoc,ThuTu,TieuDe")] BaiHoc baiHoc,
        IFormFile videoFile)
    {
        if (videoFile == null || videoFile.Length == 0)
        {
            ModelState.AddModelError("LinkVideo", "Vui lòng chọn một video để tải lên.");
        }
        else
        {
            try
            {
                string videoUrl = await _cloudinaryService.UploadFileAsync(videoFile, CloudinaryService.UploadType.Video);
                baiHoc.LinkVideo = videoUrl;
                ModelState.Remove(nameof(baiHoc.LinkVideo));
            }
            catch (Exception ex)
            {
                ModelState.AddModelError("LinkVideo", $"Lỗi khi tải video lên: {ex.Message}");
            }
        }
        baiHoc.NgayTao = DateTime.Now;
        baiHoc.MaBaiHoc = "BH" + DateTime.Now.ToString("yyMMddHHmmss") + new Random().Next(100, 999);
        ModelState.Remove(nameof(baiHoc.MaBaiHoc));
        ModelState.Remove(nameof(baiHoc.MaKhoaHocNavigation));
        if (ModelState.IsValid)
        {
            _context.Add(baiHoc);
            await _context.SaveChangesAsync();
            TempData["SuccessMessage"] = "Thêm bài học mới thành công!";
            return RedirectToAction(nameof(Index), new { maKhoaHoc = baiHoc.MaKhoaHoc });
        }
        TempData["ErrorMessage"] = "Thêm bài học thất bại. Vui lòng kiểm tra lại thông tin.";
        var khoaHoc = await _context.KhoaHocs.FindAsync(baiHoc.MaKhoaHoc);
        ViewBag.TenKhoaHoc = khoaHoc?.TieuDe;
        return View(baiHoc);
    }

    // GET: BaiHocs/Edit/MABAIHOC
    public async Task<IActionResult> Edit(string id)
    {
        if (id == null)
        {
            return BadRequest("Mã bài học không hợp lệ.");
        }
        // Lấy thẳng đối tượng BaiHoc từ DB
        var baiHoc = await _context.BaiHocs.FindAsync(id);
        if (baiHoc == null)
        {
            return NotFound();
        }
        var khoaHoc = await _context.KhoaHocs.FindAsync(baiHoc.MaKhoaHoc);
        ViewBag.TenKhoaHoc = khoaHoc?.TieuDe;
        return View(baiHoc);
    }

    // POST: BaiHocs/Edit/MABAIHOC
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(string id,
        [Bind("MaBaiHoc,MaKhoaHoc,ThuTu,TieuDe")] BaiHoc baiHoc,
        IFormFile? videoFile)
    {
        if (id != baiHoc.MaBaiHoc)
        {
            return NotFound();
        }
        ModelState.Remove(nameof(baiHoc.MaKhoaHocNavigation));
        ModelState.Remove(nameof(baiHoc.LinkVideo));
        if (ModelState.IsValid)
        {
            try
            {
                var baiHocToUpdate = await _context.BaiHocs.FindAsync(id);
                if (baiHocToUpdate == null)
                {
                    return NotFound();
                }
                baiHocToUpdate.TieuDe = baiHoc.TieuDe;
                baiHocToUpdate.ThuTu = baiHoc.ThuTu;
                if (videoFile != null && videoFile.Length > 0)
                {
                    string newVideoUrl = await _cloudinaryService.UploadFileAsync(videoFile, CloudinaryService.UploadType.Video);
                    baiHocToUpdate.LinkVideo = newVideoUrl;
                }
                await _context.SaveChangesAsync();
                TempData["SuccessMessage"] = "Cập nhật bài học thành công!";
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!BaiHocExists(baiHoc.MaBaiHoc))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }
            return RedirectToAction(nameof(Index), new { maKhoaHoc = baiHoc.MaKhoaHoc });
        }
        var kh = await _context.KhoaHocs.FindAsync(baiHoc.MaKhoaHoc);
        ViewBag.TenKhoaHoc = kh?.TieuDe;
        return View(baiHoc);
    }

   // GET: BaiHocs/Delete/MABAIHOC
public async Task<IActionResult> Delete(string id)
{
    if (id == null)
    {
        return NotFound();
    }
    var baiHoc = await _context.BaiHocs
        .Include(b => b.MaKhoaHocNavigation)
        .FirstOrDefaultAsync(m => m.MaBaiHoc == id);
        
    if (baiHoc == null)
    {
        return NotFound();
    }
    return View(baiHoc);
}

// POST: BaiHocs/Delete/MABAIHOC
[HttpPost, ActionName("Delete")]
[ValidateAntiForgeryToken]
public async Task<IActionResult> DeleteConfirmed(string id)
{
    var baiHoc = await _context.BaiHocs.FindAsync(id);
    if (baiHoc != null)
    {
        _context.BaiHocs.Remove(baiHoc);
        await _context.SaveChangesAsync();
        
        TempData["SuccessMessage"] = "Xóa bài học thành công!";
    }
    else
    {
        return NotFound();
    }
    return RedirectToAction(nameof(Index), new { maKhoaHoc = baiHoc.MaKhoaHoc });
}

    private bool BaiHocExists(string id)
    {
        return _context.BaiHocs.Any(e => e.MaBaiHoc == id);
    }
}