using WebApplication1.Models;

namespace WebApplication1.ViewModel
{
    public class LessonPlayerViewModel
    {
        public BaiHoc CurrentLesson { get; set; }
        public KhoaHoc Course { get; set; }
        public List<BaiHoc> Lessons { get; set; }
    }
}
