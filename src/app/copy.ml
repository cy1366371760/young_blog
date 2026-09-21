open! Core

type t =
  { tech : string
  ; essays : string
  ; library : string
  ; category : string
  ; choose_topic : string
  ; browse_topic : string
  ; back_to : string
  ; loading_article : string
  ; article_unavailable : string
  ; incremental_trace : string
  ; comments_boundary : string
  }

let for_locale = function
  | Locale.En ->
    { tech = "Tech"
    ; essays = "Essays"
    ; library = "Library"
    ; category = "Category"
    ; choose_topic = "Choose a topic to see its notes."
    ; browse_topic = "Browse notes in this topic."
    ; back_to = "Back to"
    ; loading_article = "Loading article..."
    ; article_unavailable = "This article is not yet available in the selected language."
    ; incremental_trace = "Incremental Trace"
    ; comments_boundary =
        "Comments boundary reserved: article id, provider adapter, moderation state."
    }
  | Locale.Zh_hans ->
    { tech = "技术"
    ; essays = "随笔"
    ; library = "文章库"
    ; category = "分类"
    ; choose_topic = "选择一个主题查看文章。"
    ; browse_topic = "浏览这个主题下的文章。"
    ; back_to = "返回"
    ; loading_article = "正在加载文章…"
    ; article_unavailable = "这篇文章尚未提供所选语言的版本。"
    ; incremental_trace = "增量计算轨迹"
    ; comments_boundary = "评论区预留：文章 ID、服务提供方适配器与审核状态。"
    }
  | Locale.Zh_hant ->
    { tech = "技術"
    ; essays = "隨筆"
    ; library = "文章庫"
    ; category = "分類"
    ; choose_topic = "選擇一個主題查看文章。"
    ; browse_topic = "瀏覽這個主題下的文章。"
    ; back_to = "返回"
    ; loading_article = "正在載入文章…"
    ; article_unavailable = "這篇文章尚未提供所選語言的版本。"
    ; incremental_trace = "增量計算軌跡"
    ; comments_boundary = "評論區預留：文章 ID、服務提供方適配器與審核狀態。"
    }
;;

let locale_label = function
  | Locale.En -> "English"
  | Locale.Zh_hans -> "简体中文"
  | Locale.Zh_hant -> "繁體中文"
;;

let area_label locale area =
  let copy = for_locale locale in
  match area with
  | Content_area.Tech -> copy.tech
  | Content_area.Essays -> copy.essays
;;

let area_description locale = function
  | Content_area.Tech ->
    (match locale with
     | Locale.En -> "Learning notes on OCaml, systems, and frontend architecture."
     | Locale.Zh_hans -> "关于 OCaml、系统与前端架构的学习笔记。"
     | Locale.Zh_hant -> "關於 OCaml、系統與前端架構的學習筆記。")
  | Content_area.Essays ->
    (match locale with
     | Locale.En -> "Reflections on everyday life, reading, memory, and fiction."
     | Locale.Zh_hans -> "记录日常、阅读、记忆与虚构的随笔。"
     | Locale.Zh_hant -> "記錄日常、閱讀、記憶與虛構的隨筆。")
;;

let path_segment_label locale = function
  | "ocaml" -> "OCaml"
  | "ocaml-learning" -> "OCaml Learning"
  | "ocaml-in-atcoder" -> "OCaml in AtCoder"
  | "bonsai" -> "Bonsai"
  | "incremental" -> "Incremental"
  | "notes" ->
    (match locale with
     | Locale.En -> "Notes"
     | Locale.Zh_hans -> "随记"
     | Locale.Zh_hant -> "隨記")
  | "daily" ->
    (match locale with
     | Locale.En -> "Daily"
     | Locale.Zh_hans -> "日常"
     | Locale.Zh_hant -> "日常")
  | segment -> String.substr_replace_all segment ~pattern:"-" ~with_:" "
;;

let trace_node_label locale node =
  match locale, node with
  | Locale.En, "all-posts" -> "all posts"
  | Locale.En, _ -> node
  | Locale.Zh_hans, "all-posts" -> "全部文章"
  | Locale.Zh_hans, "index" -> "首页"
  | Locale.Zh_hans, "category" -> "分类"
  | Locale.Zh_hans, "subcategory" -> "子分类"
  | Locale.Zh_hans, "article" -> "文章"
  | Locale.Zh_hans, "filter" -> "筛选"
  | Locale.Zh_hans, "sort" -> "排序"
  | Locale.Zh_hans, "idle" -> "空闲"
  | Locale.Zh_hans, "loading" -> "加载中"
  | Locale.Zh_hans, "loaded" -> "已加载"
  | Locale.Zh_hans, "failed" -> "失败"
  | Locale.Zh_hant, "all-posts" -> "全部文章"
  | Locale.Zh_hant, "index" -> "首頁"
  | Locale.Zh_hant, "category" -> "分類"
  | Locale.Zh_hant, "subcategory" -> "子分類"
  | Locale.Zh_hant, "article" -> "文章"
  | Locale.Zh_hant, "filter" -> "篩選"
  | Locale.Zh_hant, "sort" -> "排序"
  | Locale.Zh_hant, "idle" -> "閒置"
  | Locale.Zh_hant, "loading" -> "載入中"
  | Locale.Zh_hant, "loaded" -> "已載入"
  | Locale.Zh_hant, "failed" -> "失敗"
  | (Locale.Zh_hans | Locale.Zh_hant), _ -> node
;;

let notes_count locale count =
  match locale with
  | Locale.En -> [%string "%{count#Int} notes"]
  | Locale.Zh_hans -> [%string "%{count#Int} 篇文章"]
  | Locale.Zh_hant -> [%string "%{count#Int} 篇文章"]
;;

let subcategories_and_notes locale ~subcategory_count ~note_count =
  match locale with
  | Locale.En ->
    [%string "%{subcategory_count#Int} subcategories · %{note_count#Int} notes"]
  | Locale.Zh_hans -> [%string "%{subcategory_count#Int} 个子分类 · %{note_count#Int} 篇文章"]
  | Locale.Zh_hant -> [%string "%{subcategory_count#Int} 個子分類 · %{note_count#Int} 篇文章"]
;;
