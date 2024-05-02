-- Fungsi untuk mendapatkan waktu terakhir dimodifikasi
function getLastModified(filename)
    local command = "stat -c %y " .. filename
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()

    local lastModified = string.match(result, "(%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d)")
    return lastModified or "File tidak ditemukan"
end

-- Fungsi untuk mendapatkan waktu pembuatan file
function getCreationTime(filename)
    local command = "stat -c %w " .. filename
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()

    local creationTime = string.match(result, "(%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d)")
    return creationTime or "File tidak ditemukan"
end

-- Contoh penggunaan
local filename = "./filetype.lua"
print("Waktu terakhir dimodifikasi:", getLastModified(filename))
print("Waktu pembuatan:", getCreationTime(filename))
