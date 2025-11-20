using System;
using System.Collections.Generic;

namespace WebApplication1.Models;

public partial class MucTieuKhoaHoc
{
    public string MaKhoaHoc { get; set; } = null!;

    public int ThuTu { get; set; }

    public string NoiDung { get; set; } = null!;

    public virtual KhoaHoc MaKhoaHocNavigation { get; set; } = null!;
}
