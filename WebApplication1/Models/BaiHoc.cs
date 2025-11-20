using System;
using System.Collections.Generic;

namespace WebApplication1.Models;

public partial class BaiHoc
{
    public string MaBaiHoc { get; set; } = null!;

    public string MaKhoaHoc { get; set; } = null!;

    public int ThuTu { get; set; }

    public string? TieuDe { get; set; }

    public string LinkVideo { get; set; } = null!;

    public DateTime NgayTao { get; set; }

    public virtual KhoaHoc MaKhoaHocNavigation { get; set; } = null!;
}
