using WebApplication1.Models;

namespace WebApplication1.Services
{
    public interface ICartStudent
    {
        public Task<GioHang> DeleteCourse(string maGoiHang, string maKhoaHoc);

        public Task<GioHang> AddCourse(string maGioHang, string maKhoaHoc);
    }
}
