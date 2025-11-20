using System.Security.Claims;
using CloudinaryDotNet;
using CloudinaryDotNet.Actions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Newtonsoft.Json.Linq;
using WebApplication1.Areas.Student.ViewModels;
using WebApplication1.Models;

namespace WebApplication1.Areas.Student.Controllers
{
    [Area("Student")]
    [Authorize(Roles = "Student")]
    public class CourseController : Controller
    {
        private readonly AppDbContext _context;
        private readonly Cloudinary _cloudinary;

        public CourseController(AppDbContext context, Cloudinary cloudinary)
        {
            _context = context;
            _cloudinary = cloudinary;
        }

        [HttpGet]
        [Route("/student/coursepage")]
        public IActionResult CoursePage()
        {
            var featuredCourses = _context.KhoaHocs
                .Include(k => k.MaGiaoVienNavigation)
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
        [Route("/student/coursedetail/{id}")]
        public async Task<IActionResult> CourseDetail(string id)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            var course = await _context.KhoaHocs
                .Include(c => c.MaGiaoVienNavigation)
                .Include(c => c.MucTieuKhoaHocs)
                .Include(c => c.YeuCauKhoaHocs)
                .Include(c => c.BaiHocs)
                .FirstOrDefaultAsync(c => c.MaKhoaHoc == id);

            if (course == null)
            {
                return NotFound();
            }

            // Lấy các khóa học liên quan (cùng MonHoc, không bao gồm khóa học hiện tại)
            var relatedCourses = await _context.KhoaHocs
                .Where(c => c.MonHoc == course.MonHoc && c.MaKhoaHoc != id)
                .Take(4)
                .ToListAsync();

            // Dữ liệu tĩnh
            var includes = new List<string>
            {
                "65 giờ video theo yêu cầu",
                "85 tài liệu có thể tải xuống",
                "Truy cập trọn đời",
                "Chứng chỉ hoàn thành"
            };

            string inCourse = "false";
            if (!string.IsNullOrEmpty(userId))
            {
                var isInYourCourse = await _context.KhoaHocHocSinhs
            .AnyAsync(khhs => khhs.MaHocSinh == userId && khhs.MaKhoaHoc == id);

                if (isInYourCourse)
                {
                    inCourse = "inYourCourse";
                }
                else
                {
                    var gioHang = await _context.GioHangs
                        .FirstOrDefaultAsync(gh => gh.MaHocSinh == userId);

                    if (gioHang != null)
                    {
                        var query = _context.ChiTietGioHangs
                            .Where(ctgh => ctgh.MaGioHang == gioHang.MaGioHang && ctgh.MaKhoaHoc == id);
                        var inCart = await query.AnyAsync();

                        if (inCart)
                        {
                            inCourse = "inYourCart";
                        }
                    }
                }
            }

            // Tạo view model
            var viewModel = new CoursePageViewModel
            {
                Course = course,
                RelatedCourses = relatedCourses,
                Includes = includes,
                InCourse = inCourse
            };

            return View(viewModel);
        }

    }
}
