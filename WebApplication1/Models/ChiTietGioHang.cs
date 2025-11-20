using System;
using System.Collections.Generic;

namespace WebApplication1.Models;

public partial class ChiTietGioHang
{
    public string MaGioHang { get; set; } = null!;

    public string MaKhoaHoc { get; set; } = null!;

    public DateTime NgayThem { get; set; }

    public virtual GioHang MaGioHangNavigation { get; set; } = null!;

    public virtual KhoaHoc MaKhoaHocNavigation { get; set; } = null!;
}
