#include "health_notifications.h"
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <appmodel.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Data.Xml.Dom.h>
#include <winrt/Windows.UI.Notifications.h>
#include <ctime>
#include <stdexcept>
#include <string>

namespace {
using flutter::EncodableMap;
using flutter::EncodableValue;
using winrt::Windows::UI::Notifications::ToastNotificationManager;
using winrt::Windows::UI::Notifications::ScheduledToastNotification;
bool HasPackageIdentity() {
  UINT32 length = 0;
  return GetCurrentPackageFullName(&length, nullptr) != APPMODEL_ERROR_NO_PACKAGE;
}
int64_t Number(const EncodableMap& map, const char* key) {
  const auto found = map.find(EncodableValue(key));
  if (found == map.end()) throw std::invalid_argument("missing argument");
  if (const auto value = std::get_if<int32_t>(&found->second)) return *value;
  if (const auto value = std::get_if<int64_t>(&found->second)) return *value;
  throw std::invalid_argument("invalid argument");
}
std::string PermissionStatus() {
  if (!HasPackageIdentity()) return "unavailable";
  const auto notifier = ToastNotificationManager::CreateToastNotifier();
  return notifier.Setting() == winrt::Windows::UI::Notifications::NotificationSetting::Enabled ? "granted" : "denied";
}
}

std::unique_ptr<flutter::MethodChannel<EncodableValue>>
CreateHealthNotificationChannel(flutter::BinaryMessenger* messenger) {
  auto channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      messenger, "vn.kienphi.personal_health/notifications", &flutter::StandardMethodCodec::GetInstance());
  channel->SetMethodCallHandler([](const auto& call, auto result) {
    try {
      const auto method = call.method_name();
      if (method == "getLaunchOccurrenceId") {
        const std::wstring command = GetCommandLineW();
        const std::wstring prefix = L"suckhoe-ca-nhan://occurrence?id=";
        const auto position = command.find(prefix);
        if (position == std::wstring::npos) { result->Success(); return; }
        const auto id = std::wcstoll(command.c_str() + position + prefix.length(), nullptr, 10);
        if (id > 0 && id <= 2147483647) result->Success(EncodableValue(static_cast<int64_t>(id)));
        else result->Success();
        return;
      }
      if (method == "status" || method == "requestPermission") {
        result->Success(EncodableValue(PermissionStatus())); return;
      }
      if (!HasPackageIdentity()) {
        result->Error("package_identity_required", "Use the packaged Windows application for notifications"); return;
      }
      const auto notifier = ToastNotificationManager::CreateToastNotifier();
      if (method == "pendingIds") {
        flutter::EncodableList ids;
        for (const auto& item : notifier.GetScheduledToastNotifications()) {
          if (item.Group() == L"personal_health") {
            const auto id = std::wcstoll(item.Tag().c_str(), nullptr, 10);
            if (id > 0) ids.emplace_back(static_cast<int64_t>(id));
          }
        }
        result->Success(EncodableValue(ids)); return;
      }
      const auto* map = call.arguments() ? std::get_if<EncodableMap>(call.arguments()) : nullptr;
      if (!map) throw std::invalid_argument("missing arguments");
      const auto id = Number(*map, "id");
      if (id < 1 || id > 2147483647) throw std::invalid_argument("invalid notification id");
      const auto tag = std::to_wstring(id);
      if (method == "cancel") {
        for (const auto& item : notifier.GetScheduledToastNotifications()) {
          if (item.Tag() == tag && item.Group() == L"personal_health") notifier.RemoveFromSchedule(item);
        }
        ToastNotificationManager::History().Remove(tag, L"personal_health");
        result->Success(); return;
      }
      if (method == "schedule") {
        if (PermissionStatus() != "granted") { result->Error("permission_denied", "Notifications are disabled"); return; }
        const auto at = Number(*map, "at");
        const auto delivery = winrt::clock::from_time_t(static_cast<time_t>(at / 1000));
        if (delivery <= winrt::clock::now()) throw std::invalid_argument("past notification");
        winrt::Windows::Data::Xml::Dom::XmlDocument xml;
        const std::wstring payload = L"<toast activationType=\"protocol\" launch=\"suckhoe-ca-nhan://occurrence?id=" + tag +
          L"\"><visual><binding template=\"ToastGeneric\"><text>Đến lịch chăm sóc sức khỏe</text>"
          L"<text>Mở ứng dụng để xem lịch và xác nhận.</text></binding></visual></toast>";
        xml.LoadXml(payload);
        ScheduledToastNotification scheduled(xml, delivery);
        scheduled.Tag(tag);
        scheduled.Group(L"personal_health");
        notifier.AddToSchedule(scheduled);
        result->Success(); return;
      }
      result->NotImplemented();
    } catch (const winrt::hresult_error&) {
      result->Error("notification_native", "Windows notification operation failed");
    } catch (const std::exception&) {
      result->Error("notification_arguments", "Invalid notification request");
    }
  });
  return channel;
}
