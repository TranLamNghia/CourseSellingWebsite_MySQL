using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApplication1.Models;

namespace WebApplication1.Areas.Student.Controllers
{
    [Area("Student")]
    [Authorize(Roles = "Student")]
    public class HomeController : Controller
    {
        private readonly AppDbContext _context;

        public HomeController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        [Route("/student/homepage")]
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



    }
}
