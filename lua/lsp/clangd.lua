return {
    cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--header-insertion=never",
        "--query-driver=/usr/bin/arm-none-eabi-gcc",
    },
    init_options = {
        clangdFileStatus = true,
    },
}
