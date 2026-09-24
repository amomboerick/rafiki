# ============================================================
# Rafiki Admin Dashboard
# ============================================================
library(shiny)
library(DBI)
library(RSQLite)
library(dplyr)
library(ggplot2)
library(plotly)
library(DT)
library(scales)

# --- Config ---
DB_PATH <- "../rafiki.db"

INDIGO  <- "#4F46E5"
CORAL   <- "#FF6B6B"
INK     <- "#1F2937"
MUTED   <- "#6B7280"
BG      <- "#F9FAFB"
CARD    <- "#FFFFFF"
BORDER  <- "#E5E7EB"
GREEN   <- "#10B981"
AMBER   <- "#F59E0B"
RED     <- "#EF4444"

# --- DB helpers ---
get_con <- function() dbConnect(SQLite(), DB_PATH)

q <- function(sql) {
  con <- get_con()
  on.exit(dbDisconnect(con))
  dbGetQuery(con, sql)
}

exec <- function(sql) {
  con <- get_con()
  on.exit(dbDisconnect(con))
  dbExecute(con, sql)
}

# --- KPI value box ---
kpi_box <- function(title, value, accent = INDIGO, icon = "*") {
  div(class = "kpi-card", style = paste0("border-top: 4px solid ", accent, ";"),
    div(class = "kpi-label", title),
    div(class = "kpi-value", style = paste0("color:", accent, ";"), value),
    div(class = "kpi-icon", icon)
  )
}

# ============================================================
# UI
# ============================================================
ui <- fluidPage(
  tags$head(
    tags$title("Rafiki - Admin"),
    tags$style(HTML(paste0("
      body { background:", BG, "; font-family: 'Inter','Segoe UI',system-ui,sans-serif; color:", INK, "; }
      .navbar-rafiki {
        background: linear-gradient(90deg,", INDIGO, " 0%,", CORAL, " 100%);
        padding: 18px 32px; margin-bottom: 24px;
        display:flex; align-items:center; justify-content:space-between;
        box-shadow: 0 4px 12px rgba(79,70,229,0.15);
      }
      .navbar-rafiki h1 { color:#fff; margin:0; font-size:24px; font-weight:700; letter-spacing:-0.5px; }
      .navbar-rafiki .tag { color: rgba(255,255,255,0.85); font-size:13px; }
      .kpi-card {
        background:", CARD, "; border-radius:12px; padding:20px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.06); position:relative;
        margin-bottom:16px; min-height:120px;
      }
      .kpi-label { color:", MUTED, "; font-size:12px; text-transform:uppercase; letter-spacing:0.6px; font-weight:600; }
      .kpi-value { font-size:34px; font-weight:800; margin-top:6px; letter-spacing:-1px; }
      .kpi-icon  { position:absolute; top:16px; right:20px; font-size:26px; opacity:0.15; }
      .nav-tabs { border-bottom: 2px solid ", BORDER, "; margin-bottom:20px; }
      .nav-tabs > li > a { color:", MUTED, "; font-weight:600; border:none; padding:12px 20px; }
      .nav-tabs > li.active > a,
      .nav-tabs > li.active > a:hover,
      .nav-tabs > li.active > a:focus {
        color:", INDIGO, " !important; background:transparent !important;
        border:none !important; border-bottom: 3px solid ", INDIGO, " !important;
      }
      .nav-tabs > li > a:hover { color:", INDIGO, "; background:transparent; border:none; }
      .card {
        background:", CARD, "; border-radius:12px; padding:20px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.06); margin-bottom:20px;
      }
      .card h3 { margin-top:0; color:", INK, "; font-weight:700; font-size:18px; }
      table.dataTable { font-size:13px; }
      .dataTables_wrapper .dataTables_filter input {
        border-radius:8px; border:1px solid ", BORDER, "; padding:6px 10px;
      }
      .alert-banner {
        background:#FEF3C7; border-left:4px solid ", AMBER, ";
        padding:14px 20px; border-radius:8px; margin-bottom:20px;
        color:#92400E; font-weight:600;
      }
      .provider-card {
        background:", CARD, "; border:1px solid ", BORDER, "; border-radius:12px;
        padding:18px; margin-bottom:14px; box-shadow: 0 1px 3px rgba(0,0,0,0.04);
      }
      .provider-card h4 { margin:0 0 4px; font-size:16px; font-weight:700; color:", INK, "; }
      .provider-card .meta { color:", MUTED, "; font-size:13px; margin-bottom:8px; }
      .provider-card .bio { color:", INK, "; font-size:13px; line-height:1.5; margin-bottom:14px; }
      .btn-approve {
        background:", GREEN, "; color:#fff; border:none; padding:8px 20px;
        border-radius:8px; font-weight:600; cursor:pointer; margin-right:8px;
        transition: all 0.2s;
      }
      .btn-approve:hover { background:#059669; transform: translateY(-1px); }
      .btn-reject {
        background:#fff; color:", RED, "; border:1px solid ", RED, "; padding:8px 20px;
        border-radius:8px; font-weight:600; cursor:pointer; transition: all 0.2s;
      }
      .btn-reject:hover { background:", RED, "; color:#fff; }
      .badge-verified   { background:#DCFCE7; color:#166534; padding:3px 10px; border-radius:999px; font-size:12px; font-weight:600; }
      .badge-pending    { background:#FEF3C7; color:#92400E; padding:3px 10px; border-radius:999px; font-size:12px; font-weight:600; }
      .badge-unverified { background:#F3F4F6; color:#4B5563; padding:3px 10px; border-radius:999px; font-size:12px; font-weight:600; }
      .badge-rejected   { background:#FEE2E2; color:#991B1B; padding:3px 10px; border-radius:999px; font-size:12px; font-weight:600; }
    "))),
    tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
    tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700;800&display=swap")
  ),

  div(class = "navbar-rafiki",
    div(
      h1("Rafiki"),
      div(class = "tag", "Local Services - Kenya")
    ),
    div(class = "tag", "Admin Dashboard - v0.2")
  ),

  div(style = "padding: 0 32px 40px;",

    uiOutput("pending_banner"),

    fluidRow(
      column(3, uiOutput("kpi_users")),
      column(3, uiOutput("kpi_providers")),
      column(3, uiOutput("kpi_services")),
      column(3, uiOutput("kpi_verified"))
    ),

    tabsetPanel(
      id = "tabs",

      tabPanel("Overview",
        fluidRow(
          column(6, div(class = "card",
            h3("Providers by Group"),
            plotlyOutput("chart_group", height = "360px")
          )),
          column(6, div(class = "card",
            h3("Providers by Nairobi Sub-County"),
            plotlyOutput("chart_county", height = "360px")
          ))
        ),
        fluidRow(
          column(6, div(class = "card",
            h3("Top Rated Providers"),
            DTOutput("tbl_top_rated")
          )),
          column(6, div(class = "card",
            h3("Verification Status"),
            plotlyOutput("chart_verif", height = "300px")
          ))
        )
      ),

      tabPanel("Verification Queue",
        div(class = "card",
          h3("Pending Verification"),
          p(style = paste0("color:", MUTED, "; font-size:13px; margin-bottom:20px;"),
            "Click Approve to mark a provider as verified, or Reject to decline. Changes take effect instantly."),
          uiOutput("queue_ui")
        )
      ),

      tabPanel("Providers",
        div(class = "card",
          h3("All Providers"),
          p(style = paste0("color:", MUTED, "; font-size:13px;"),
            "Click a row to see options. Use the Status dropdown in the row to change a provider's verification status."),
          DTOutput("tbl_providers")
        )
      ),

      tabPanel("Services",
        div(class = "card",
          h3("All Services"),
          DTOutput("tbl_services")
        )
      ),

      tabPanel("Bookings",
        div(class = "card",
          h3("All Bookings"),
          p(style = paste0("color:", MUTED, "; font-size:13px; margin-bottom:20px;"),
            "Bookings will appear here once clients start booking services."),
          DTOutput("tbl_bookings")
        )
      ),

      tabPanel("Categories",
        div(class = "card",
          h3("Rafiki Service Categories"),
          DTOutput("tbl_categories")
        )
      )
    )
  )
)

# ============================================================
# SERVER
# ============================================================
server <- function(input, output, session) {

  # Reactive trigger to refresh everything after an admin action
  refresh <- reactiveVal(0)

  # ---- Pending banner ----
  output$pending_banner <- renderUI({
    refresh()
    n <- q("SELECT COUNT(*) AS n FROM provider_profiles WHERE verification_status='pending'")$n
    if (n > 0) {
      div(class = "alert-banner",
        paste0("⚠️  ", n, " provider", if (n > 1) "s" else "", " awaiting verification. Check the Verification Queue tab.")
      )
    } else {
      NULL
    }
  })

  # ---- KPIs ----
  output$kpi_users <- renderUI({
    refresh()
    n <- q("SELECT COUNT(*) AS n FROM users")$n
    kpi_box("Total Users", format(n, big.mark=","), INDIGO, "U")
  })
  output$kpi_providers <- renderUI({
    refresh()
    n <- q("SELECT COUNT(*) AS n FROM provider_profiles")$n
    kpi_box("Providers", format(n, big.mark=","), CORAL, "P")
  })
  output$kpi_services <- renderUI({
    refresh()
    n <- q("SELECT COUNT(*) AS n FROM services")$n
    kpi_box("Active Services", format(n, big.mark=","), INDIGO, "S")
  })
  output$kpi_verified <- renderUI({
    refresh()
    n <- q("SELECT COUNT(*) AS n FROM provider_profiles WHERE verification_status='verified'")$n
    kpi_box("Verified Providers", format(n, big.mark=","), GREEN, "V")
  })

  # ---- Verification Queue with buttons ----
  output$queue_ui <- renderUI({
    refresh()
    df <- q("
      SELECT pp.id AS pid, u.full_name AS name, u.phone AS phone,
             u.sub_county AS area, pp.years_experience AS yrs,
             pp.avg_rating AS rating, pp.bio AS bio
      FROM provider_profiles pp
      JOIN users u ON u.id = pp.user_id
      WHERE pp.verification_status = 'pending'
      ORDER BY pp.created_at DESC
    ")

    if (nrow(df) == 0) {
      return(div(style = paste0("padding:40px; text-align:center; color:", MUTED, ";"),
        h4("🎉 All caught up!"),
        p("No providers pending verification.")
      ))
    }

    tagList(lapply(1:nrow(df), function(i) {
      r <- df[i, ]
      div(class = "provider-card",
        h4(r$name),
        div(class = "meta",
          paste0("📞 ", r$phone, "  ·  📍 ", ifelse(is.na(r$area), "Nairobi", r$area),
                 "  ·  ⭐ ", round(r$rating, 2), "  ·  ", r$yrs, " yrs exp")
        ),
        if (!is.na(r$bio)) div(class = "bio", r$bio),
        actionButton(paste0("approve_", r$pid), "✅ Approve", class = "btn-approve"),
        actionButton(paste0("reject_", r$pid), "❌ Reject", class = "btn-reject")
      )
    }))
  })

  # ---- Approve / Reject handlers ----
  observe({
    refresh()
    df <- q("SELECT id FROM provider_profiles WHERE verification_status='pending'")
    for (pid in df$id) {
      local({
        my_pid <- pid
        observeEvent(input[[paste0("approve_", my_pid)]], {
          exec(paste0("UPDATE provider_profiles SET verification_status='verified' WHERE id=", my_pid))
          showNotification(paste0("✅ Provider #", my_pid, " approved"), type = "message", duration = 3)
          refresh(refresh() + 1)
        }, ignoreInit = TRUE)

        observeEvent(input[[paste0("reject_", my_pid)]], {
          exec(paste0("UPDATE provider_profiles SET verification_status='rejected' WHERE id=", my_pid))
          showNotification(paste0("❌ Provider #", my_pid, " rejected"), type = "warning", duration = 3)
          refresh(refresh() + 1)
        }, ignoreInit = TRUE)
      })
    }
  })

  # ---- Charts ----
  output$chart_group <- renderPlotly({
    refresh()
    df <- q("
      SELECT sc.category_group AS grp, COUNT(DISTINCT s.provider_id) AS n
      FROM services s
      JOIN service_categories sc ON sc.id = s.category_id
      GROUP BY sc.category_group
      ORDER BY n DESC
    ")
    plot_ly(df, x = ~grp, y = ~n, type = "bar",
            marker = list(color = INDIGO, line = list(color = INDIGO))) %>%
      layout(
        xaxis = list(title = "", tickangle = -30, color = MUTED),
        yaxis = list(title = "", color = MUTED),
        plot_bgcolor = CARD, paper_bgcolor = CARD,
        margin = list(t = 10, b = 60)
      ) %>%
      config(displayModeBar = FALSE)
  })

  output$chart_county <- renderPlotly({
    refresh()
    df <- q("
      SELECT u.sub_county AS sc, COUNT(DISTINCT pp.id) AS n
      FROM provider_profiles pp
      JOIN users u ON u.id = pp.user_id
      WHERE u.sub_county IS NOT NULL
      GROUP BY u.sub_county
      ORDER BY n DESC
    ")
    plot_ly(df, y = ~reorder(sc, n), x = ~n, type = "bar", orientation = "h",
            marker = list(color = CORAL, line = list(color = CORAL))) %>%
      layout(
        xaxis = list(title = "", color = MUTED),
        yaxis = list(title = "", color = MUTED),
        plot_bgcolor = CARD, paper_bgcolor = CARD,
        margin = list(l = 100, t = 10, b = 30)
      ) %>%
      config(displayModeBar = FALSE)
  })

  output$chart_verif <- renderPlotly({
    refresh()
    df <- q("
      SELECT verification_status AS v, COUNT(*) AS n
      FROM provider_profiles GROUP BY verification_status
    ")
    colors <- c(verified="#10B981", pending="#F59E0B",
                unverified="#E5E7EB", rejected="#EF4444")
    plot_ly(df, labels = ~v, values = ~n, type = "pie", hole = 0.6,
            marker = list(colors = colors[df$v])) %>%
      layout(showlegend = TRUE, paper_bgcolor = CARD,
             margin = list(t = 10, b = 10)) %>%
      config(displayModeBar = FALSE)
  })

  # ---- Providers Table ----
  output$tbl_providers <- renderDT({
    refresh()
    df <- q("
      SELECT
        pp.id AS ProviderID,
        u.full_name AS Name,
        u.phone AS Phone,
        u.sub_county AS Area,
        pp.years_experience AS Yrs,
        ROUND(pp.avg_rating,2) AS Rating,
        pp.total_reviews AS Reviews,
        pp.total_bookings AS Bookings,
        pp.verification_status AS Status
      FROM provider_profiles pp
      JOIN users u ON u.id = pp.user_id
      ORDER BY pp.avg_rating DESC
    ")
    datatable(df, rownames = FALSE,
      options = list(pageLength = 15, scrollX = TRUE,
                     columnDefs = list(list(visible = FALSE, targets = 0))),
      callback = JS("
        table.on('click', 'tr', function() {
          var data = table.row(this).data();
          if (data) Shiny.setInputValue('picked_provider', data[0], {priority: 'event'});
        });
      ")
    ) %>%
      formatStyle("Rating", color = styleInterval(c(3.5, 4.5), c(RED, AMBER, GREEN))) %>%
      formatStyle("Status",
        backgroundColor = styleEqual(
          c("verified","pending","unverified","rejected"),
          c("#DCFCE7","#FEF3C7","#F3F4F6","#FEE2E2")
        )
      )
  })

  # Handle row click from providers table
  observeEvent(input$picked_provider, {
    pid <- input$picked_provider
    showModal(modalDialog(
      title = paste0("Provider #", pid, " — Change Status"),
      easyClose = TRUE,
      footer = tagList(
        actionButton("modal_verify", "✅ Mark Verified", class = "btn-approve"),
        actionButton("modal_pending", "⏳ Mark Pending", class = "btn-reject"),
        actionButton("modal_reject", "❌ Mark Rejected", class = "btn-reject"),
        modalButton("Cancel")
      )
    ))
  })

  observeEvent(input$modal_verify, {
    pid <- input$picked_provider
    exec(paste0("UPDATE provider_profiles SET verification_status='verified' WHERE id=", pid))
    removeModal()
    showNotification(paste0("Provider #", pid, " → verified"), type = "message")
    refresh(refresh() + 1)
  })
  observeEvent(input$modal_pending, {
    pid <- input$picked_provider
    exec(paste0("UPDATE provider_profiles SET verification_status='pending' WHERE id=", pid))
    removeModal()
    showNotification(paste0("Provider #", pid, " → pending"), type = "warning")
    refresh(refresh() + 1)
  })
  observeEvent(input$modal_reject, {
    pid <- input$picked_provider
    exec(paste0("UPDATE provider_profiles SET verification_status='rejected' WHERE id=", pid))
    removeModal()
    showNotification(paste0("Provider #", pid, " → rejected"), type = "error")
    refresh(refresh() + 1)
  })

  # ---- Services Table ----
  output$tbl_services <- renderDT({
    refresh()
    df <- q("
      SELECT
        s.id AS ID,
        s.title AS Service,
        sc.name AS Category,
        sc.category_group AS Grp,
        CAST(s.base_price AS REAL) AS Price_KES,
        s.price_unit AS Unit,
        u.full_name AS Provider,
        u.sub_county AS Area,
        pp.verification_status AS Status
      FROM services s
      JOIN service_categories sc ON sc.id = s.category_id
      JOIN provider_profiles pp ON pp.id = s.provider_id
      JOIN users u ON u.id = pp.user_id
      ORDER BY sc.category_group, s.title
    ")
    datatable(df, rownames = FALSE, options = list(pageLength = 15, scrollX = TRUE)) %>%
      formatCurrency("Price_KES", currency = "KSh ", interval = 3, mark = ",", digits = 0) %>%
      formatStyle("Status",
        backgroundColor = styleEqual(
          c("verified","pending","unverified","rejected"),
          c("#DCFCE7","#FEF3C7","#F3F4F6","#FEE2E2")
        )
      )
  })

  # ---- Bookings Table ----
  output$tbl_bookings <- renderDT({
    refresh()
    df <- q("
      SELECT b.reference AS Ref, b.booking_type AS Type,
             b.status AS Status, b.scheduled_at AS Scheduled,
             CAST(b.total_amount AS REAL) AS Total_KES,
             uc.full_name AS Client, up.full_name AS Provider,
             sc.name AS Category
      FROM bookings b
      LEFT JOIN users uc ON uc.id = b.client_id
      LEFT JOIN provider_profiles pp ON pp.id = b.provider_id
      LEFT JOIN users up ON up.id = pp.user_id
      LEFT JOIN services s ON s.id = b.service_id
      LEFT JOIN service_categories sc ON sc.id = s.category_id
      ORDER BY b.created_at DESC
    ")
    if (nrow(df) == 0) {
      return(datatable(data.frame(Message = "No bookings yet"),
                       rownames = FALSE, options = list(dom = 't')))
    }
    datatable(df, rownames = FALSE, options = list(pageLength = 15, scrollX = TRUE))
  })

  # ---- Categories Table ----
  output$tbl_categories <- renderDT({
    df <- q("
      SELECT id AS ID, name AS Category, category_group AS Grp,
             default_deposit_pct AS Deposit_Pct
      FROM service_categories ORDER BY category_group, name
    ")
    datatable(df, rownames = FALSE, options = list(pageLength = 20, scrollX = TRUE)) %>%
      formatStyle("Grp", fontWeight = "600", color = INDIGO)
  })

  # ---- Top Rated ----
  output$tbl_top_rated <- renderDT({
    refresh()
    df <- q("
      SELECT u.full_name AS Provider, u.sub_county AS Area,
             ROUND(pp.avg_rating,2) AS Rating, pp.total_reviews AS Reviews,
             pp.verification_status AS Status
      FROM provider_profiles pp
      JOIN users u ON u.id = pp.user_id
      ORDER BY pp.avg_rating DESC
      LIMIT 5
    ")
    datatable(df, rownames = FALSE, options = list(dom = 't', scrollX = TRUE)) %>%
      formatStyle("Rating", color = GREEN, fontWeight = "700")
  })
}

shinyApp(ui, server)