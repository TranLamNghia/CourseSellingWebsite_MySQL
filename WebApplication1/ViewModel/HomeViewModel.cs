using WebApplication1.Models;

namespace WebApplication1.ViewModel
{
    public class HomeViewModel
    {
        public List<KhoaHoc> FeaturedCourses { get; set; }
        public List<string> Subjects { get; set; }
        public string UserName { get; set; }
        public string Email { get; set; }
        public string AvatarUrl { get; set; }
        public string Role { get; set; }
    }
}
