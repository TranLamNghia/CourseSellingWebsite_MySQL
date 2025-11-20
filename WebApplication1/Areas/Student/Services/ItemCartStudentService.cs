using Microsoft.EntityFrameworkCore;
using WebApplication1.Models;

namespace WebApplication1.Areas.Student.Services
{
    public class ItemCartStudentService : ICartStudent
    {
        private readonly AppDbContext _context;

        public ItemCartStudentService(AppDbContext context)
        {
            _context = context;
        }

        public async Task<GioHang> AddCourse(string maGioHang, string maKhoaHoc)
        {
            var gioHang = await _context.GioHangs
                .FirstOrDefaultAsync(gh => gh.MaGioHang == maGioHang);

            var chiTietGioHang = new ChiTietGioHang
            {
                MaGioHang = maGioHang,
                MaKhoaHoc = maKhoaHoc,
                NgayThem = DateTime.Now
            };

            _context.ChiTietGioHangs.Add(chiTietGioHang);
            await _context.SaveChangesAsync();

            return gioHang;
        }

        public async Task<GioHang> DeleteCourse(string maGioHang, string maKhoaHoc)
        {
            var chiTietGioHang = await _context.ChiTietGioHangs
                .FirstOrDefaultAsync(ctgh => ctgh.MaGioHang == maGioHang && ctgh.MaKhoaHoc == maKhoaHoc);

            _context.ChiTietGioHangs.Remove(chiTietGioHang);
            await _context.SaveChangesAsync();

            // Lấy lại thông tin giỏ hàng sau khi xóa
            var gioHang = await _context.GioHangs
                .FirstOrDefaultAsync(gh => gh.MaGioHang == maGioHang);

            return gioHang;
        }
    }
}
