using System;
using System.Collections.Generic;

namespace WebApplication1.Models;

public partial class KhoaHoc
{
    public string MaKhoaHoc { get; set; } = null!;

    public string MonHoc { get; set; } = null!;

    public string TieuDe { get; set; } = null!;

    public string? DuongDanAnhKhoaHoc { get; set; }

    public string MoTa { get; set; } = null!;

    public decimal GiaKhoaHoc { get; set; }

    public int ThoiHan { get; set; }

    public string MaGiaoVien { get; set; } = null!;

    public DateTime NgayCapNhat { get; set; }

    public virtual ICollection<BaiHoc> BaiHocs { get; set; } = new List<BaiHoc>();

    public virtual ICollection<ChiTietGioHang> ChiTietGioHangs { get; set; } = new List<ChiTietGioHang>();

    public virtual ICollection<KhoaHocHocSinh> KhoaHocHocSinhs { get; set; } = new List<KhoaHocHocSinh>();

    public virtual GiaoVien MaGiaoVienNavigation { get; set; } = null!;

    public virtual ICollection<MucTieuKhoaHoc> MucTieuKhoaHocs { get; set; } = new List<MucTieuKhoaHoc>();

    public virtual ICollection<YeuCauKhoaHoc> YeuCauKhoaHocs { get; set; } = new List<YeuCauKhoaHoc>();
}
