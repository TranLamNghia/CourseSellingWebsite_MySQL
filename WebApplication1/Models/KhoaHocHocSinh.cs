using System;
using System.Collections.Generic;

namespace WebApplication1.Models;

public partial class KhoaHocHocSinh
{
    public string MaKhoaHoc { get; set; } = null!;

    public string MaHocSinh { get; set; } = null!;

    public DateTime NgayDangKy { get; set; }

    public virtual HocSinh MaHocSinhNavigation { get; set; } = null!;

    public virtual KhoaHoc MaKhoaHocNavigation { get; set; } = null!;
}
