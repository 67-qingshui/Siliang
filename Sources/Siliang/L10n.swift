import Foundation

// UI languages: 中文 (default) + 日本語 (switchable). Data format stays ja-JP.

enum K: String {
    // App / nav
    case appName
    case navSplit, navPoints, navItems, navToken, navAdmin, navSettings
    case navSplitSub, navPointsSub, navItemsSub, navTokenSub, navAdminSub, navSettingsSub
    case navGroupRecord, navGroupSystem

    // Common
    case save, cancel, delete, add, edit, confirm, close, none, total, amount, date, name, actions

    // Login / onboarding
    case loginTitle, username, password, passwordConfirm, loginSubmit, forgotPassword
    case onboardTitle, onboardSubtitle, createAndLogin, recoveryKeyTitle, recoveryKeyHint, copyRecoveryKey
    case resetTitle, resetHint, recoverKey, newPassword, resetSubmit, resetDone, resetInvalid
    case loginError, missingField, logout, passwordMismatch, copied, continueToApp

    // Split (割り勘)
    case splitTitle, splitSubtitle, splitNew, splitNewRepayment, income, expense, equal, custom
    case payer, payerTag, participants, splitSettlement, oweTitle, netTitle, receivable, toPay
    case splitCalendar, monthTotal, membersTitle, addMember, recordList, titlePlaceholder
    case direction, paidBy, noMembers, addMemberFirst, splitMode, amountInvalid, customSumMismatch
    case monthIncome, monthExpense, monthBalance, settlementHint, settlementEmptyHint, all, noSearchResult

    // Repayment
    case repaymentFrom, repaymentTo, repaymentAmount

    // Points (积分)
    case pointsTitle, pointsSubtitle, pointsNew, earned, spent, plan, addPlan, addPlanFirst, pointsBalance, pending, noPending, expectedDate, memo, pointsCalendar
    case pointsUnit, filterPlan, clearFilter, deleted

    // Items (物品)
    case itemsTitle, itemsSubtitle, itemsNew, category, categorySuggest, startTime, endTime, active, finished, itemsCalendar
    case usedDuration, yearUnit, monthUnit, dayUnit, totalItems, itemList, toToday, nameRequired, endBeforeStart

    // Token
    case tokenTitle, tokenSubtitle, tokenNew, scenario, model, apiKey, inputTokens, outputTokens, cost, tokenGrouped, tokenCalendar, noApiKey
    case totalTokens, totalCost, scenarioCount, filterScenario, recordCount, recentScenarios, tokenCountInvalid

    // Admin
    case adminTitle, adminSubtitle, usersTitle, role, adminRole, memberRole, changePassword, recoveryKey, regenerate, addUser
    case you, showHide, userExists

    // Settings
    case settingsTitle, settingsSubtitle, language, languageHint, chinese, japanese, syncFolder, chooseFolder, syncNow, synced, noSyncFolder
    case syncHint, syncDesc

    // Calendar / heatmap
    case heatmapLess, heatmapMore, noData, year, periodRange

    // Placeholder / misc
    case search
}

struct L10n {
    static func s(_ k: K, _ lang: AppLanguage) -> String {
        switch lang {
        case .zh: return zh[k] ?? k.rawValue
        case .ja: return ja[k] ?? zh[k] ?? k.rawValue
        }
    }

    static let zh: [K: String] = [
        .appName: "司量",

        .navSplit: "割り勘", .navSplitSub: "AA 记账与结算",
        .navPoints: "积分记录", .navPointsSub: "计划 · 余额",
        .navItems: "物品使用", .navItemsSub: "周期 · 区间",
        .navToken: "Token 使用", .navTokenSub: "场景 · 消耗",
        .navAdmin: "管理员", .navAdminSub: "用户 · 密钥",
        .navSettings: "设置", .navSettingsSub: "语言 · 同步",
        .navGroupRecord: "记录", .navGroupSystem: "系统",

        .save: "保存", .cancel: "取消", .delete: "删除", .add: "添加", .edit: "编辑",
        .confirm: "确定", .close: "关闭", .none: "无", .total: "合计",
        .amount: "金额", .date: "日期", .name: "名称", .actions: "操作",

        .loginTitle: "登录", .username: "用户名", .password: "密码", .passwordConfirm: "确认密码",
        .loginSubmit: "登录",
        .forgotPassword: "忘记密码？",
        .loginError: "用户名或密码错误", .missingField: "请填写所有必填项", .logout: "退出登录",
        .passwordMismatch: "两次输入的密码不一致", .copied: "已复制", .continueToApp: "继续使用 →",

        .onboardTitle: "创建管理员", .onboardSubtitle: "首次启动，请创建管理员账号",
        .createAndLogin: "创建并登录", .recoveryKeyTitle: "恢复密钥", .recoveryKeyHint: "请妥善保存此密钥。忘记密码时，它是重置密码的唯一凭证。",
        .copyRecoveryKey: "复制恢复密钥",

        .resetTitle: "重置密码", .resetHint: "输入恢复密钥以重置密码", .recoverKey: "恢复密钥",
        .newPassword: "新密码", .resetSubmit: "重置密码", .resetDone: "密码已重置，请用新密码登录",
        .resetInvalid: "恢复密钥不正确",

        .splitTitle: "割り勘", .splitSubtitle: "朋友之间的 AA 记账与结算",
        .splitNew: "记一笔", .splitNewRepayment: "登记还款",
        .income: "收入", .expense: "支出", .equal: "均分", .custom: "自定义金额",
        .payer: "付款人", .payerTag: "付款", .participants: "参与人", .splitSettlement: "结算汇总",
        .oweTitle: "谁该付谁多少", .netTitle: "净账（还差多少）", .receivable: "应收", .toPay: "应付",
        .splitCalendar: "收支日历", .monthTotal: "当月合计", .membersTitle: "成员库",
        .addMember: "添加成员", .recordList: "明细", .titlePlaceholder: "名称 / 备注",
        .direction: "方向", .paidBy: "付款人", .noMembers: "暂无成员", .addMemberFirst: "请先在成员库添加成员",
        .splitMode: "分摊方式", .amountInvalid: "请输入有效金额", .customSumMismatch: "分摊合计与总额不一致: ",
        .monthIncome: "本月收入", .monthExpense: "本月支出", .monthBalance: "本月结余",
        .settlementHint: "净额已自动抵消", .settlementEmptyHint: "记一笔或登记还款后自动计算",
        .all: "全部", .noSearchResult: "没有匹配的记录",

        .repaymentFrom: "还款人", .repaymentTo: "收款人", .repaymentAmount: "还款金额",

        .pointsTitle: "积分记录", .pointsSubtitle: "积分计划 · 余额 · 待入账",
        .pointsNew: "记一笔", .earned: "获得", .spent: "消耗",
        .plan: "积分计划", .addPlan: "添加计划", .addPlanFirst: "请先添加积分计划",
        .pointsBalance: "账户余额", .pending: "待入账", .noPending: "无待入账",
        .expectedDate: "预计到账日期", .memo: "备注", .pointsCalendar: "积分日历",
        .pointsUnit: "pt", .filterPlan: "只看此计划", .clearFilter: "清除筛选",
        .deleted: "已删除",

        .itemsTitle: "物品使用", .itemsSubtitle: "物品使用周期 · 区间一览",
        .itemsNew: "记一件物品", .category: "分类", .categorySuggest: "常用分类",
        .startTime: "开始时间", .endTime: "结束时间", .active: "使用中", .finished: "已结束",
        .itemsCalendar: "使用区间", .usedDuration: "已使用", .yearUnit: "年", .monthUnit: "个月", .dayUnit: "天",
        .totalItems: "物品总数", .itemList: "物品清单", .toToday: "至今",
        .nameRequired: "请填写物品名称", .endBeforeStart: "结束时间不能早于开始时间",

        .tokenTitle: "Token 使用", .tokenSubtitle: "按应用场景统计模型消耗",
        .tokenNew: "记一笔", .scenario: "应用场景", .model: "模型",
        .apiKey: "API Key", .inputTokens: "输入 Tokens", .outputTokens: "输出 Tokens",
        .cost: "费用", .tokenGrouped: "按应用场景分组", .tokenCalendar: "Token 日历", .noApiKey: "（未填写）",
        .totalTokens: "累计 Tokens", .totalCost: "累计费用", .scenarioCount: "应用场景",
        .filterScenario: "只看此场景", .recordCount: "共", .recentScenarios: "最近场景",
        .tokenCountInvalid: "输入 / 输出 Tokens 至少一项大于 0",

        .adminTitle: "管理员", .adminSubtitle: "用户管理 · 恢复密钥",
        .usersTitle: "用户管理", .role: "角色", .adminRole: "管理员",
        .memberRole: "成员", .changePassword: "改密码", .recoveryKey: "恢复密钥",
        .regenerate: "重新生成", .addUser: "添加用户",
        .you: "你", .showHide: "显示 / 隐藏", .userExists: "用户名已存在",

        .settingsTitle: "设置", .settingsSubtitle: "语言 · 数据同步 · 关于",
        .language: "语言", .languageHint: "界面语言 (数据格式保持 ja-JP)",
        .chinese: "中文", .japanese: "日本語",
        .syncFolder: "同步文件夹", .chooseFolder: "选择文件夹", .syncNow: "立即同步",
        .synced: "已同步", .noSyncFolder: "未设置同步文件夹",
        .syncHint: "选择 iCloud / Dropbox 等同步目录, 换设备自动合并数据",
        .syncDesc: "最后写入优先 + 删除墓碑, 多设备安全合并",

        .heatmapLess: "少", .heatmapMore: "多", .noData: "暂无数据", .year: "年", .periodRange: "周期区间",
        .search: "搜索",
    ]

    static let ja: [K: String] = [
        .appName: "司量",

        .navSplit: "割り勘", .navSplitSub: "割り勘・精算",
        .navPoints: "ポイント", .navPointsSub: "プラン・残高",
        .navItems: "アイテム", .navItemsSub: "期間・記録",
        .navToken: "Token 利用", .navTokenSub: "シーン・消費",
        .navAdmin: "管理者", .navAdminSub: "ユーザー・キー",
        .navSettings: "設定", .navSettingsSub: "言語・同期",
        .navGroupRecord: "記録", .navGroupSystem: "システム",

        .save: "保存", .cancel: "キャンセル", .delete: "削除", .add: "追加", .edit: "編集",
        .confirm: "OK", .close: "閉じる", .none: "なし", .total: "合計",
        .amount: "金額", .date: "日付", .name: "名称", .actions: "操作",

        .loginTitle: "ログイン", .username: "ユーザー名", .password: "パスワード", .passwordConfirm: "パスワード（確認）",
        .loginSubmit: "ログイン",
        .forgotPassword: "パスワードを忘れた？",
        .loginError: "ユーザー名またはパスワードが違います", .missingField: "すべての必須項目を入力してください", .logout: "ログアウト",
        .passwordMismatch: "パスワードが一致しません", .copied: "コピーしました", .continueToApp: "続ける →",

        .onboardTitle: "管理者を作成", .onboardSubtitle: "初回起動です。管理者アカウントを作成してください",
        .createAndLogin: "作成してログイン", .recoveryKeyTitle: "リカバリーキー", .recoveryKeyHint: "このキーを大切に保管してください。パスワードを忘れたときの唯一の復旧手段です。",
        .copyRecoveryKey: "リカバリーキーをコピー",

        .resetTitle: "パスワード再設定", .resetHint: "リカバリーキーを入力して再設定してください", .recoverKey: "リカバリーキー",
        .newPassword: "新しいパスワード", .resetSubmit: "パスワードを再設定", .resetDone: "再設定しました。新しいパスワードでログインしてください",
        .resetInvalid: "リカバリーキーが正しくありません",

        .splitTitle: "割り勘", .splitSubtitle: "友達との割り勘・精算",
        .splitNew: "記録する", .splitNewRepayment: "返済を記録",
        .income: "収入", .expense: "支出", .equal: "均等割り", .custom: "金額を個別指定",
        .payer: "支払者", .payerTag: "支払", .participants: "参加者", .splitSettlement: "精算サマリー",
        .oweTitle: "誰が誰にいくら払うか", .netTitle: "残高（あとどれだけ）", .receivable: "受取", .toPay: "支払",
        .splitCalendar: "収支カレンダー", .monthTotal: "当月合計", .membersTitle: "メンバー",
        .addMember: "メンバー追加", .recordList: "明細", .titlePlaceholder: "名称 / メモ",
        .direction: "方向", .paidBy: "支払者", .noMembers: "メンバーがいません", .addMemberFirst: "先にメンバーを追加してください",
        .splitMode: "分担方法", .amountInvalid: "有効な金額を入力してください", .customSumMismatch: "分担合計が合計と一致しません: ",
        .monthIncome: "今月の収入", .monthExpense: "今月の支出", .monthBalance: "今月の収支",
        .settlementHint: "相殺済み", .settlementEmptyHint: "記録すると自動計算されます",
        .all: "すべて", .noSearchResult: "該当する記録がありません",

        .repaymentFrom: "返済者", .repaymentTo: "受取者", .repaymentAmount: "返済金額",

        .pointsTitle: "ポイント", .pointsSubtitle: "プラン・残高・入金予定",
        .pointsNew: "記録する", .earned: "獲得", .spent: "消費",
        .plan: "ポイントプラン", .addPlan: "プラン追加", .addPlanFirst: "先にプランを追加してください",
        .pointsBalance: "残高", .pending: "入金予定", .noPending: "入金予定なし",
        .expectedDate: "入金予定日", .memo: "メモ", .pointsCalendar: "ポイントカレンダー",
        .pointsUnit: "pt", .filterPlan: "このプランのみ表示", .clearFilter: "フィルタ解除",
        .deleted: "削除済み",

        .itemsTitle: "アイテム", .itemsSubtitle: "使用期間の記録と管理",
        .itemsNew: "アイテム追加", .category: "カテゴリ", .categorySuggest: "よく使うカテゴリ",
        .startTime: "開始日", .endTime: "終了日", .active: "使用中", .finished: "終了",
        .itemsCalendar: "使用期間", .usedDuration: "使用期間", .yearUnit: "年", .monthUnit: "ヶ月", .dayUnit: "日",
        .totalItems: "アイテム数", .itemList: "アイテム一覧", .toToday: "現在",
        .nameRequired: "アイテム名を入力してください", .endBeforeStart: "終了日は開始日より後にしてください",

        .tokenTitle: "Token 利用", .tokenSubtitle: "シーン別のモデル消費統計",
        .tokenNew: "記録する", .scenario: "利用シーン", .model: "モデル",
        .apiKey: "API Key", .inputTokens: "入力 Tokens", .outputTokens: "出力 Tokens",
        .cost: "コスト", .tokenGrouped: "シーン別集計", .tokenCalendar: "Token カレンダー", .noApiKey: "（未入力）",
        .totalTokens: "累計 Tokens", .totalCost: "累計コスト", .scenarioCount: "シーン数",
        .filterScenario: "このシーンのみ表示", .recordCount: "計", .recentScenarios: "最近のシーン",
        .tokenCountInvalid: "入力・出力 Tokens のどちらかは 0 より大きくしてください",

        .adminTitle: "管理者", .adminSubtitle: "ユーザー管理・リカバリーキー",
        .usersTitle: "ユーザー管理", .role: "役割", .adminRole: "管理者",
        .memberRole: "メンバー", .changePassword: "パスワード変更", .recoveryKey: "リカバリーキー",
        .regenerate: "再生成", .addUser: "ユーザー追加",
        .you: "あなた", .showHide: "表示 / 非表示", .userExists: "ユーザー名は既に存在します",

        .settingsTitle: "設定", .settingsSubtitle: "言語・データ同期・情報",
        .language: "言語", .languageHint: "UI 言語 (データ形式は ja-JP 固定)",
        .chinese: "中文", .japanese: "日本語",
        .syncFolder: "同期フォルダ", .chooseFolder: "フォルダを選択", .syncNow: "今すぐ同期",
        .synced: "同期しました", .noSyncFolder: "同期フォルダが設定されていません",
        .syncHint: "iCloud / Dropbox などの同期ディレクトリを選択すると、別の端末と自動でマージされます",
        .syncDesc: "LWW + トゥームストーンによる安全なマージ",

        .heatmapLess: "少", .heatmapMore: "多", .noData: "データなし", .year: "年", .periodRange: "期間",
        .search: "検索",
    ]
}