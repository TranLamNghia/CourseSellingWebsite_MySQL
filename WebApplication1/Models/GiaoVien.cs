using System;
using System.Collections.Generic;

namespace WebApplication1.Models;

public partial class GiaoVien
{
    public string MaGiaoVien { get; set; } = null!;

    public string HoTen { get; set; } = null!;

    public string? DuongDanAnhDaiDien { get; set; }

    public string Email { get; set; } = null!;

    public string? DienThoai { get; set; }

    public string? GioiThieu { get; set; }

    public DateTime NgayTao { get; set; }

    public virtual ICollection<KhoaHoc> KhoaHocs { get; set; } = new List<KhoaHoc>();
}
