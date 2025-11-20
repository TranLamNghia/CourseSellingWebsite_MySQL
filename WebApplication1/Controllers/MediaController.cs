using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApplication1.Models; // Thay bằng namespace của Models
using WebApplication1.Services;
using System.Threading.Tasks;

namespace WebApplication1.Controllers
{
    public class MediaController : Controller
    {
        private readonly CloudinaryService _cloudinaryService;
        private readonly AppDbContext _context;

        public MediaController(CloudinaryService cloudinaryService, AppDbContext context)
        {
            _cloudinaryService = cloudinaryService;
            _context = context;
        }

        // Upload ảnh đại diện giáo viên
        [HttpGet]
        public IActionResult UploadTeacherAvatar()
        {
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> UploadTeacherAvatar(IFormFile file, string maGiaoVien)
        {
            try
            {
                if (file != null && file.Length > 0)
                {
                    var avatarUrl = await _cloudinaryService.UploadFileAsync(file, CloudinaryService.UploadType.Avatar);
                    var teacher = await _context.GiaoViens.FindAsync(maGiaoVien);
                    if (teacher != null)
                    {
                        teacher.DuongDanAnhDaiDien = avatarUrl;
                        await _context.SaveChangesAsync();
                        TempData["Message"] = "Upload ảnh đại diện thành công!";
                    }
                    else
                    {
                        TempData["Message"] = "Không tìm thấy giáo viên.";
                    }
                }
                else
                {
                    TempData["Message"] = "Vui lòng chọn file để upload.";
                }
            }
            catch (Exception ex)
            {
                TempData["Message"] = $"Lỗi: {ex.Message}";
            }
            return View();
        }

        // Upload ảnh khóa học
        [HttpGet]
        public IActionResult UploadCourseImage()
        {
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> UploadCourseImage(IFormFile file, string maKhoaHoc)
        {
            try
            {
                if (file != null && file.Length > 0)
                {
                    var imageUrl = await _cloudinaryService.UploadFileAsync(file, CloudinaryService.UploadType.CourseImage);
                    var course = await _context.KhoaHocs.FindAsync(maKhoaHoc);
                    if (course != null)
                    {
                        course.DuongDanAnhKhoaHoc = imageUrl;
                        await _context.SaveChangesAsync();
                        TempData["Message"] = "Upload ảnh khóa học thành công!";
                    }
                    else
                    {
                        TempData["Message"] = "Không tìm thấy khóa học.";
                    }
                }
                else
                {
                    TempData["Message"] = "Vui lòng chọn file để upload.";
                }
            }
            catch (Exception ex)
            {
                TempData["Message"] = $"Lỗi: {ex.Message}";
            }
            return View();
        }

        // Upload video bài học
        [HttpGet]
        public IActionResult UploadLessonVideo()
        {
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> UploadLessonVideo(IFormFile file, string maKhoaHoc, int thuTu, string tieuDe)
        {
            try
            {
                if (file != null && file.Length > 0)
                {
                    var videoUrl = await _cloudinaryService.UploadFileAsync(file, CloudinaryService.UploadType.Video);
                    var lesson = new BaiHoc
                    {
                        MaKhoaHoc = maKhoaHoc,
                        ThuTu = thuTu,
                        TieuDe = tieuDe,
                        LinkVideo = videoUrl,
                        NgayTao = DateTime.Now
                    };
                    _context.BaiHocs.Add(lesson); // Trigger sẽ tự tạo MaBaiHoc và cập nhật SoLuongBaiHoc
                    await _context.SaveChangesAsync();
                    TempData["Message"] = "Upload video bài học thành công!";
                }
                else
                {
                    TempData["Message"] = "Vui lòng chọn file để upload.";
                }
            }
            catch (Exception ex)
            {
                TempData["Message"] = $"Lỗi: {ex.Message}";
            }
            return View();
        }
    }
}