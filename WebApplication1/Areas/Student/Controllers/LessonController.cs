using CloudinaryDotNet;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApplication1.Areas.Student.ViewModel;
using WebApplication1.Models;

namespace WebApplication1.Areas.Student.Controllers
{

    [Area("Student")]
    [Authorize(Roles = "Student")]
    public class LessonController : Controller
    {
        private readonly AppDbContext _context;
        private readonly Cloudinary _cloudinary;

        public LessonController(AppDbContext context, Cloudinary cloudinary)
        {
            _context = context;
            _cloudinary = cloudinary;
        }

        [HttpGet]
        [Route("/student/lessonplayer/{lessonId}")]
        public async Task<IActionResult> LessonPlayer(string lessonId)
        {
            var course = await _context.KhoaHocs
                .Include(c => c.MaGiaoVienNavigation)
                .Include(c => c.BaiHocs)
                .FirstOrDefaultAsync(c => c.MaKhoaHoc == lessonId);

            if (course == null)
            {
                return NotFound();
            }

            var firstLesson = await _context.BaiHocs
                .Where(b => b.MaKhoaHoc == lessonId && b.ThuTu == 1)
                .FirstOrDefaultAsync();

            if (firstLesson == null)
            {
                return Content("Không tìm thấy bài học đầu tiên cho khóa học này.");
            }

            var lessons = await _context.BaiHocs
                .Where(b => b.MaKhoaHoc == lessonId)
                .OrderBy(b => b.ThuTu)
                .ToListAsync();

            var viewModel = new LessonPlayerViewModel
            {
                CurrentLesson = firstLesson,
                Course = course,
                Lessons = lessons
            };

            return View(viewModel);
        }
    }
}
