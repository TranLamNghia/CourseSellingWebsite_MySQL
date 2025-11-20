using WebApplication1.Models;

namespace WebApplication1.Areas.Student.Services
{
    public interface ICartStudent
    {
        public Task<GioHang> DeleteCourse(string maGoiHang, string maKhoaHoc);

        public Task<GioHang> AddCourse(string maGioHang, string maKhoaHoc);
    }
}
