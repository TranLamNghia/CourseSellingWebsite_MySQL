using CloudinaryDotNet;
using CloudinaryDotNet.Actions;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Newtonsoft.Json.Linq;
using System.Security.Claims;
using WebApplication1.Models;
using WebApplication1.ViewModel;

namespace WebApplication1.Controllers
{
    //[Area("Student")]
    //[Authorize(Roles = "Student")]
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
        public IActionResult CoursePage(string? maMonHoc, string? keyword, string? sort)
        {
            var khoaHocQuery = _context.KhoaHocs
                .Include(k => k.MaGiaoVienNavigation).AsQueryable();

            //var subjects = _context.KhoaHocs
            //    .GroupBy(k => k.MonHoc)
            //    .Select(g => new { Subject = g.Key, Count = g.Count() })
            //    .ToList();

            //var subjects = _context.MonHocs
            //    .Select(mh => new
            //    {
            //        Subject = mh.TenMonHoc,
            //        Count = _context.KhoaHocs.Count(kh => kh.MaMonHoc == mh.MaMonHoc)
            //    })
            //    .ToList();

            if (!string.IsNullOrEmpty(maMonHoc))
            {
                khoaHocQuery = khoaHocQuery.Where(kh => kh.MaMonHoc == maMonHoc);
            }

            if (!string.IsNullOrEmpty(keyword))
            {
                khoaHocQuery = khoaHocQuery.Where(c =>
                    c.TieuDe.Contains(keyword));
            }

            khoaHocQuery = sort switch
            {
                "price-low" => khoaHocQuery.OrderBy(c => c.GiaKhoaHoc),
                "price-high" => khoaHocQuery.OrderByDescending(c => c.GiaKhoaHoc),
                _ => khoaHocQuery
            };
            var featuredCourses = khoaHocQuery.ToList();

            var subjects = _context.MonHocs
            .Select(mh => new
            {
                MaMonHoc = mh.MaMonHoc,
                Subject = mh.TenMonHoc,
                Count = _context.KhoaHocs.Count(kh => kh.MaMonHoc == mh.MaMonHoc)
            })
            .ToList();

            var viewModel = new
            {
                FeaturedCourses = featuredCourses,
                Subjects = subjects,
                SelectedMaMonHoc = maMonHoc,
                Keyword = keyword,
                Sort = sort
            };

            return View(viewModel);
        }

        [HttpGet]
        [Route("/student/coursedetail/{id}")]
        public async Task<IActionResult> CourseDetail(string id)
        {
            if (User.Identity.IsAuthenticated)
            {
                var idUser = User.FindFirstValue(ClaimTypes.NameIdentifier);
                var userExist = await _context.HocSinhs.AnyAsync(h => h.MaHocSinh == idUser && h.IsActive == true);

                if (!userExist)
                {
                    await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
                    
                }
            }
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

        [HttpGet]
        [Route("/student/getlessonpreview/{lessonId}")]
        public async Task<IActionResult> GetLessonPreview(string lessonId)
        {
            var lesson = await _context.BaiHocs
                .FirstOrDefaultAsync(b => b.MaBaiHoc == lessonId);

            if (lesson == null) return NotFound();

            return Json(new
            {
                title = lesson.TieuDe,
                videoUrl = lesson.LinkVideo 
            });
        }

    }
}
