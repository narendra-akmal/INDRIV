# ==============================================================================
# Nama Skrip    : InstalDriver.ps1
# Deskripsi     : Skrip otomatisasi PowerShell untuk memeriksa, mengunduh, 
#                 dan menginstal pembaruan driver Windows via modul PSWindowsUpdate.
# Bahasa        : Bahasa Indonesia
# Lisensi       : MIT
# ==============================================================================

# 1. Pastikan skrip dijalankan sebagai Administrator
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Host "[SISTEM] Hak akses Administrator diperlukan!" -ForegroundColor Red
    Write-Host "[SISTEM] Silakan buka PowerShell kembali dengan klik kanan 'Run as Administrator'." -ForegroundColor Yellow
    Read-Host -Prompt "Tekan Enter untuk keluar.. "
	Exit
}

Clear-Host
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "         SKRIP PEMBARUAN & INSTALASI DRIVER WINDOWS         " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# 2. Pengaturan Kebijakan Eksekusi (Execution Policy)
Write-Host "[1/4] Memeriksa kebijakan eksekusi PowerShell..." -ForegroundColor Yellow
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
Write-Host "     -> Kebijakan eksekusi diatur ke RemoteSigned untuk sesi ini." -ForegroundColor Green
Write-Host ""

# 3. Pemeriksaan dan Instalasi Modul PSWindowsUpdate
Write-Host "[2/4] Memeriksa modul PSWindowsUpdate..." -ForegroundColor Yellow
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Host "     -> Modul PSWindowsUpdate belum terpasang. Memulai instalasi..." -ForegroundColor Cyan
    try {
        # Memastikan NuGet provider terpasang
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop | Out-Null
        # Menginstal modul PSWindowsUpdate dari PSGallery
        Install-Module -Name PSWindowsUpdate -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
        Write-Host "     -> Modul PSWindowsUpdate berhasil dipasang!" -ForegroundColor Green
    }
    catch {
        Write-Host "     [ERROR] Gagal memasang modul PSWindowsUpdate: $_" -ForegroundColor Red
        Exit
    }
} else {
    Write-Host "     -> Modul PSWindowsUpdate sudah terpasang." -ForegroundColor Green
}

Import-Module PSWindowsUpdate
Write-Host ""

# 4. Pencarian Driver yang Tersedia
Write-Host "[3/4] Mencari pembaruan driver yang tersedia dari Windows Update..." -ForegroundColor Yellow
Write-Host "     (Proses ini dapat memakan waktu beberapa menit, harap tunggu...)" -ForegroundColor Gray
Write-Host ""

$DaftarDriver = Get-WindowsUpdate -UpdateType Driver -ErrorAction SilentlyContinue

if ($null -eq $DaftarDriver -or $DaftarDriver.Count -eq 0) {
    Write-Host "------------------------------------------------------------" -ForegroundColor Green
    Write-Host "[HASIL] Semua driver hardware telah diperbarui! Tidak ada driver baru yang tersedia." -ForegroundColor Green
    Write-Host "------------------------------------------------------------" -ForegroundColor Green
    Write-Host ""
    Exit
}

Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Daftar Driver Terdeteksi:" -ForegroundColor White
Write-Host "------------------------------------------------------------" -ForegroundColor Cyan

foreach ($driver in $DaftarDriver) {
    Write-Host " * [$($driver.KB)] $($driver.Title)" -ForegroundColor White
}

Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Total Driver Ditemukan: $($DaftarDriver.Count)" -ForegroundColor Yellow
Write-Host ""

# 5. Konfirmasi dan Pemasangan Driver
$Konfirmasi = Read-Host "Apakah Anda ingin melanjutkan instalasi driver di atas? (Y/N)"

if ($Konfirmasi -eq 'Y' -or $Konfirmasi -eq 'y') {
    Write-Host ""
    Write-Host "[4/4] Memulai proses pengunduhan dan instalasi driver..." -ForegroundColor Yellow
    
    # Jalankan instalasi driver
    Get-WindowsUpdate -UpdateType Driver -Install -AcceptAll -IgnoreReboot -Verbose
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "    PROSES INSTALASI DRIVER SELESAI DILAKUKAN              " -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    
    # Konfirmasi restart jika diperlukan
    Write-Host ""
    $Restart = Read-Host "Beberapa driver mungkin memerlukan *restart*. Restart komputer sekarang? (Y/N)"
    if ($Restart -eq 'Y' -or $Restart -eq 'y') {
        Write-Host "[SISTEM] Memulai ulang sistem dalam 5 detik..." -ForegroundColor Red
        Start-Sleep -Seconds 5
        Restart-Computer -Force
    } else {
        Write-Host "[SISTEM] Silakan *restart* komputer Anda secara manual nanti." -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "[SISTEM] Instalasi dibatalkan oleh pengguna." -ForegroundColor Red
}
