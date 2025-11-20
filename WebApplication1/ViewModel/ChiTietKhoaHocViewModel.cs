namespace WebApplication1.ViewModel
{
    public class ChiTietKhoaHocViewModel
    {
        public string MaKhoaHoc { get; set; }
        public string TieuDeKhoaHoc { get; set; }
        public List<BaiHocViewModel> DanhSachBaiHoc { get; set; }
        public string LinkVideoBanDau { get; set; }
        public string TieuDeBaiHocBanDau { get; set; }
    }
}