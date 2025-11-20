using WebApplication1.Models;

namespace WebApplication1.Areas.Student.ViewModel
{
    public class MyCartViewModel
    {
        public string MaGioHang { get; set; }
        public List<KhoaHoc> CartItems { get; set; }
        public int TotalItems { get; set; }
        public decimal TotalPrice { get; set; }
    }
}
