using System;
using System.Collections.Generic;

namespace WebApplication1.Models;

public partial class HocSinh
{
    public string MaHocSinh { get; set; } = null!;

    public string HoTen { get; set; } = null!;

    public string PassHash { get; set; } = null!;

    public string? DuongDanAnhDaiDien { get; set; }

    public string Email { get; set; } = null!;

    public string? DienThoai { get; set; }

    public DateOnly? NgaySinh { get; set; }

    public string? GioiTinh { get; set; }

    public string? DiaChi { get; set; }

    public DateTime NgayDangKy { get; set; }

    public virtual ICollection<GioHang> GioHangs { get; set; } = new List<GioHang>();

    public virtual ICollection<KhoaHocHocSinh> KhoaHocHocSinhs { get; set; } = new List<KhoaHocHocSinh>();
}
