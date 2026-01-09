using WebApplication1.Models;

namespace WebApplication1.ViewModel
{
    public class CoursePageViewModel
    {
        public KhoaHoc Course { get; set; }
        public List<KhoaHoc> RelatedCourses { get; set; }
        public List<string> Includes { get; set; }
        public string InCourse { get; set; }
    }
}