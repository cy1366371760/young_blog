type t =
  { search : string
  ; search_hint : string
  ; clear : string
  ; save : string
  ; saved : string
  ; all : string
  ; only_saved : string
  ; refresh : string
  ; settings : string
  ; font : string
  ; system : string
  ; light : string
  ; dark : string
  ; share : string
  ; empty : string
  ; empty_hint : string
  ; offline : string
  ; categories : string
  ; reading : string
  ; library : string
  ; local : string
  ; retry : string
  }

let for_locale = function
  | Locale.En ->
    { search = "Search articles"
    ; search_hint = "Title, summary, or tag…"
    ; clear = "Clear filters"
    ; save = "Save article"
    ; saved = "Saved"
    ; all = "All notes"
    ; only_saved = "Saved notes"
    ; refresh = "Refresh library"
    ; settings = "Reading settings"
    ; font = "Text size"
    ; system = "System"
    ; light = "Light"
    ; dark = "Dark"
    ; share = "Share article"
    ; empty = "No matching notes"
    ; empty_hint = "Try another search or clear your filters."
    ; offline = "Your library travels with you."
    ; categories = "Topics"
    ; reading = "Read slowly. Stay curious."
    ; library = "A personal field notebook"
    ; local = "Included articles work offline. Refresh to save new notes."
    ; retry = "Try again"
    }
  | Locale.Zh_hans ->
    { search = "搜索文章"
    ; search_hint = "标题、摘要或标签…"
    ; clear = "清除筛选"
    ; save = "收藏文章"
    ; saved = "已收藏"
    ; all = "全部文章"
    ; only_saved = "我的收藏"
    ; refresh = "更新文章库"
    ; settings = "阅读设置"
    ; font = "正文字号"
    ; system = "跟随系统"
    ; light = "浅色"
    ; dark = "深色"
    ; share = "分享文章"
    ; empty = "没有匹配的文章"
    ; empty_hint = "试试其他关键词，或清除筛选条件。"
    ; offline = "把文章带在身边，随时阅读。"
    ; categories = "文章分类"
    ; reading = "慢慢读，保持好奇。"
    ; library = "一个人的学习与生活笔记"
    ; local = "内置文章可离线阅读，更新文章库即可保存新文章。"
    ; retry = "重试"
    }
  | Locale.Zh_hant ->
    { search = "搜尋文章"
    ; search_hint = "標題、摘要或標籤…"
    ; clear = "清除篩選"
    ; save = "收藏文章"
    ; saved = "已收藏"
    ; all = "全部文章"
    ; only_saved = "我的收藏"
    ; refresh = "更新文章庫"
    ; settings = "閱讀設定"
    ; font = "正文字號"
    ; system = "跟隨系統"
    ; light = "淺色"
    ; dark = "深色"
    ; share = "分享文章"
    ; empty = "沒有符合的文章"
    ; empty_hint = "試試其他關鍵字，或清除篩選條件。"
    ; offline = "把文章帶在身邊，隨時閱讀。"
    ; categories = "文章分類"
    ; reading = "慢慢讀，保持好奇。"
    ; library = "一個人的學習與生活筆記"
    ; local = "內建文章可離線閱讀，更新文章庫即可儲存新文章。"
    ; retry = "重試"
    }
;;
