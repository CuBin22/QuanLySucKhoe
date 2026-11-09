namespace Health.Api;
public static class RequestSecurity
{
 public static void Validate(bool development,bool https,byte[] expectedHash,string supplied,string device)
 {
  if(!development && !https)throw new ApiProblem(400,"Yêu cầu HTTPS.");
  if(supplied.Length>512 || !System.Security.Cryptography.CryptographicOperations.FixedTimeEquals(expectedHash,System.Security.Cryptography.SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(supplied))))throw new ApiProblem(401,"Khóa truy cập API không hợp lệ.");
  if(!System.Text.RegularExpressions.Regex.IsMatch(device,"^[a-f0-9]{32}$"))throw new ApiProblem(400,"Thiếu mã thiết bị hợp lệ.");
 }
}
