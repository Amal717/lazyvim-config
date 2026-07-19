return {
    cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--header-insertion=never",
    },
    init_options = {
        clangdFileStatus = true,
    },
}
