using CloudinaryDotNet;
using CloudinaryDotNet.Actions;
using Microsoft.AspNetCore.Http;
using System;
using System.IO;
using System.Threading.Tasks;

namespace WebApplication1.Services
{
    public class CloudinaryService
    {
        private readonly Cloudinary _cloudinary;

        public CloudinaryService()
        {
            // Khởi tạo Cloudinary từ thông tin cấu hình
            Account account = new Account(
                "druj32kwu",      // Thay bằng cloud name
                "344847971657135",         // Thay bằng API key
                "0wSxIVVMFozFmq8K-wZyAvu-yWY"       // Thay bằng API secret
            );

            _cloudinary = new Cloudinary(account);
            _cloudinary.Api.Secure = true;
        }

        public enum UploadType
        {
            CourseImage,
            Avatar,
            Video
        }

        public async Task<string> UploadFileAsync(IFormFile file, UploadType type)
        {
            if (file == null || file.Length == 0)
                throw new ArgumentException("File không hợp lệ.");

            var folder = GetFolderName(type);
            var fileName = Path.GetFileNameWithoutExtension(file.FileName);

            using var stream = file.OpenReadStream();

            if (type == UploadType.Video)
            {
                var videoParams = new VideoUploadParams()
                {
                    File = new FileDescription(file.FileName, stream),
                    Folder = folder,
                    PublicId = fileName
                };

                var uploadResult = await _cloudinary.UploadAsync(videoParams);

                if (uploadResult.StatusCode != System.Net.HttpStatusCode.OK)
                    throw new Exception("Tải video lên thất bại.");

                return uploadResult.SecureUrl.ToString();
            }
            else
            {
                var imageParams = new ImageUploadParams()
                {
                    File = new FileDescription(file.FileName, stream),
                    Folder = folder,
                    PublicId = fileName,
                    Transformation = new Transformation().Quality("auto").FetchFormat("auto")
                };

                var uploadResult = await _cloudinary.UploadAsync(imageParams);

                if (uploadResult.StatusCode != System.Net.HttpStatusCode.OK)
                    throw new Exception("Tải ảnh lên thất bại.");

                return uploadResult.SecureUrl.ToString();
            }
        }

        private string GetFolderName(UploadType type)
        {
            return type switch
            {
                UploadType.CourseImage => "course_images",
                UploadType.Avatar => "avatars",
                UploadType.Video => "videos",
                _ => "others"
            };
        }
        public string UploadImage(IFormFile file)
        {
            if (file == null || file.Length == 0)
                return null;

            using var stream = file.OpenReadStream();
            var uploadParams = new ImageUploadParams()
            {
                File = new FileDescription(file.FileName, stream)
            };

            var uploadResult = _cloudinary.Upload(uploadParams);
            return uploadResult.SecureUrl.ToString();
        }
        public async Task<string> UploadImageAsync(IFormFile file)
        {
            var uploadParams = new ImageUploadParams
            {
                File = new FileDescription(file.FileName, file.OpenReadStream())
            };

            var uploadResult = await _cloudinary.UploadAsync(uploadParams);

            return uploadResult.SecureUrl.ToString();
        }
        public async Task DeleteFileAsync(string fileUrl)
        {
            if (string.IsNullOrEmpty(fileUrl))
            {
                return;
            }
            var uri = new Uri(fileUrl);
            var lastSegment = uri.Segments.LastOrDefault();

            if (string.IsNullOrEmpty(lastSegment))
            {
                return;
            }
            var publicId = Path.GetFileNameWithoutExtension(lastSegment);
            var resourceType = ResourceType.Video;
            if (fileUrl.Contains("/image/upload/"))
            {
                resourceType = ResourceType.Image;
            }
            else if (fileUrl.Contains("/raw/upload/"))
            {
                resourceType = ResourceType.Raw;
            }
            var deletionParams = new DeletionParams(publicId)
            {
                ResourceType = resourceType
            };
            var result = await _cloudinary.DestroyAsync(deletionParams);
            if (result.Result != "ok")
            {
                throw new Exception($"Không thể xóa file trên Cloudinary. Lý do: {result.Error?.Message}");
            }
        }
    }
}
