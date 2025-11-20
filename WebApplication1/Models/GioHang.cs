using System;
using System.Collections.Generic;

namespace WebApplication1.Models;

public partial class GioHang
{
    public string MaGioHang { get; set; } = null!;

    public string MaHocSinh { get; set; } = null!;

    public DateTime NgayTao { get; set; }

    public virtual ICollection<ChiTietGioHang> ChiTietGioHangs { get; set; } = new List<ChiTietGioHang>();

    public virtual HocSinh MaHocSinhNavigation { get; set; } = null!;
}
