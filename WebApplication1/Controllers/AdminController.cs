using Microsoft.AspNetCore.Mvc;
using WebApplication1.Models;
using WebApplication1.ViewModel;
using WebApplication1.ViewModels;

namespace WebApplication1.Controllers
{
    public class AdminController : Controller
    {
        private readonly AppDbContext _context;

        public AdminController(AppDbContext context)
        {
            _context = context;
        }

        public IActionResult Dashboard()
        {
            try
            {
                var viewModel = new AdminDashboardVM
                {
                    SoLuongKhoaHoc = _context.KhoaHocs.Count(),
                    SoLuongHocVien = _context.HocSinhs.Count(),
                    SoLuongGiaoVien = _context.GiaoViens.Count()
                };

                return View(viewModel);
            }
            catch (Exception ex)
            {
                return Content($"Lỗi: {ex.Message}");
            }
        }
                                                                    
    }
}
