library(data.table)
library(plyr)
library(dplyr)
options(gsubfn.engine = "R")
library(sqldf)
library(tictoc)

# Working directory and initial setup
setwd("path")

set.seed(100)

options(scipen = 3)

# Load the data
data <- read.csv("Data/LuminateDataExport_UTDP2_011818.csv")

# Time test- dplyr
tic("dplyr and sqldf time test")

# Clean the data
names(data) <- tolower(names(data))

# Remove the unwanted characters
data <- as.data.frame(lapply(data, gsub, pattern = "\\$", replacement = ""))

data <- as.data.frame(lapply(data, gsub, pattern = ",", replacement = ""))

data <- as.data.frame(lapply(data, gsub, pattern = " ", replacement = ""))

important <- select(data, -event_date, -city, -company_goal, -company_name, -fundraising_goal, -state, -street, -team_count, -team_member_goal, -team_name, -zip, -gifts_count, -registration_gift)

# Convert everything to character
imp_1 <- data.frame(lapply(important, as.character), stringsAsFactors = FALSE)

# Function to convert numeric columns
conversion <- function(x) {
  
  stopifnot(is.list(x))
  
  x[] <- rapply(x, utils::type.convert, classes = "character", how = "replace", as.is = TRUE)
  
  return(x)
}

# Conversion
imp_2 <- conversion(imp_1)

# Factor columns
cols <- c("event_year", "name", "participant_id", "team_captain", "team_id", "match_code", "tap_level", "tap_desc")

imp_2[cols] <- lapply(imp_2[cols], factor)

# Add team count
imp_2 <- imp_2 %>% group_by(team_id) %>% mutate(team_count = n()) 

# Sum up $$
team_totals <- aggregate(total_gifts ~ team_id + event_year, data = imp_2, FUN = sum)
personal_totals <- aggregate(total_gifts ~ participant_id + event_year, data = imp_2, FUN = sum)

years <- imp_2 %>% group_by(event_year) %>% summarise(total = sum(total_gifts))
total <- sum(imp_2$total_gifts)

# Top 10% of teams and individuals and events
n <- 10

top_teams_total <- subset(team_totals, total_gifts > quantile(total_gifts, prob = 1 - n/100))

top_walkers_total <- subset(personal_totals, total_gifts > quantile(total_gifts, prob = 1 - n/100))

# Sum top 10% nums
team_total <- sum(top_teams_total$total)

walker_total <- sum(top_walkers_total$total_gifts)

# By year
top_team_y1 <- team_totals %>% filter(event_year == "FY2015") %>% subset(total_gifts > quantile(total_gifts, prob = 1 - n/100))
top_team_y2 <- team_totals %>% filter(event_year == "FY2016") %>% subset(total_gifts > quantile(total_gifts, prob = 1 - n/100))
top_team_y3 <- team_totals %>% filter(event_year == "FY2017") %>% subset(total_gifts > quantile(total_gifts, prob = 1 - n/100))

top_walker_y1 <- personal_totals %>% filter(event_year == "FY2015") %>% subset(total_gifts > quantile(total_gifts, prob = 1 - n/100))
top_walker_y2 <- personal_totals %>% filter(event_year == "FY2016") %>% subset(total_gifts > quantile(total_gifts, prob = 1 - n/100))
top_walker_y3 <- personal_totals %>% filter(event_year == "FY2017") %>% subset(total_gifts > quantile(total_gifts, prob = 1 - n/100))

# Combine top teams and top walkers
imp_2$top_team <- as.factor(ifelse(imp_2$team_id %in% top_teams_total$team_id, 1, 0))
imp_2$top_walker <- as.factor(ifelse(imp_2$participant_id %in% top_walkers_total$participant_id, 1, 0))

imp_2$y1_top_walker <- as.factor(ifelse(imp_2$participant_id %in% top_walker_y1$participant_id, 1, 0))
imp_2$y2_top_walker <- as.factor(ifelse(imp_2$participant_id %in% top_walker_y2$participant_id, 1, 0))
imp_2$y3_top_walker <- as.factor(ifelse(imp_2$participant_id %in% top_walker_y3$participant_id, 1, 0))

imp_2$y1_top_team <- as.factor(ifelse(imp_2$team_id %in% top_team_y1$team_id, 1, 0))
imp_2$y2_top_team <- as.factor(ifelse(imp_2$team_id %in% top_team_y2$team_id, 1, 0))
imp_2$y3_top_team <- as.factor(ifelse(imp_2$team_id %in% top_team_y3$team_id, 1, 0))

# Fill empty segments info
imp_2$tap_desc <- sub("^$", 0, imp_2$tap_desc)

# Tapestry information
tap_info <- imp_2 %>% filter(match_code != "UX000" & top_walker == 1) 

no_info <- imp_2 %>% filter(match_code == "UX000" & top_walker == 1)

# Summarize tapestry segments
seg_summ <- tap_info %>% group_by(tap_desc) %>% summarise(raised = sum(total_gifts), count = n())

# Event totals
event_summ <- imp_2 %>% group_by(name) %>% summarise(event_total = sum(total_gifts), count = n())

# Group top events and segments
top_segments_total <- subset(seg_summ, raised > quantile(raised, prob = 1 - n/100))
top_events_total <- subset(event_summ, event_total > quantile(event_total, prob = 1 - n/100))

top_segment_total <- sum(top_segments_total$raised)
top_event_total <- sum(top_events_total$event_total)

# By year
y1_top_event <- imp_2 %>% filter(event_year == "FY2015") %>% group_by(name) %>% summarise(event_year_total = sum(total_gifts)) %>% subset(event_year_total > quantile(event_year_total, prob = 1 - n/100))
y2_top_event <- imp_2 %>% filter(event_year == "FY2016") %>% group_by(name) %>% summarise(event_year_total = sum(total_gifts)) %>% subset(event_year_total > quantile(event_year_total, prob = 1 - n/100)) 
y3_top_event <- imp_2 %>% filter(event_year == "FY2017") %>% group_by(name) %>% summarise(event_year_total = sum(total_gifts)) %>% subset(event_year_total > quantile(event_year_total, prob = 1 - n/100)) 

imp_2$y1_top_event <- as.factor(ifelse(imp_2$name %in% y1_top_event$name, 1, 0))
imp_2$y2_top_event <- as.factor(ifelse(imp_2$name %in% y2_top_event$name, 1, 0))
imp_2$y3_top_event <- as.factor(ifelse(imp_2$name %in% y3_top_event$name, 1, 0))

imp_2$top_event <- as.factor(ifelse(imp_2$name %in% top_events_total$name, 1, 0))

# By segment
y1_top_segment <- imp_2 %>% filter(event_year == "FY2015") %>% group_by(tap_desc) %>% summarise(segment_total = sum(total_gifts)) %>% subset(segment_total > quantile(segment_total, prob = 1 - n/100))
y2_top_segment <- imp_2 %>% filter(event_year == "FY2016") %>% group_by(tap_desc) %>% summarise(segment_total = sum(total_gifts)) %>% subset(segment_total > quantile(segment_total, prob = 1 - n/100)) 
y3_top_segment <- imp_2 %>% filter(event_year == "FY2017") %>% group_by(tap_desc) %>% summarise(segment_total = sum(total_gifts)) %>% subset(segment_total > quantile(segment_total, prob = 1 - n/100)) 

imp_2$y1_top_segment <- as.factor(ifelse(imp_2$tap_desc %in% y1_top_segment$tap_desc, 1, 0))
imp_2$y2_top_segment <- as.factor(ifelse(imp_2$tap_desc %in% y2_top_segment$tap_desc, 1, 0))
imp_2$y3_top_segment <- as.factor(ifelse(imp_2$tap_desc %in% y3_top_segment$tap_desc, 1, 0))

imp_2$top_segment <- as.factor(ifelse(imp_2$tap_desc %in% top_segments_total$tap_desc, 1, 0))

# Create df for RF model of top_walker
walker_dat <- imp_2 %>% group_by(participant_id) %>% mutate(y1_personal = ifelse(event_year == "FY2015", sum(total_gifts), 0),
                                                            y2_personal = ifelse(event_year == "FY2016", sum(total_gifts), 0),
                                                            y3_personal = ifelse(event_year == "FY2017", sum(total_gifts), 0),
                                                            y1_team = ifelse(event_year == "FY2015", sum(team_total_gifts), 0),
                                                            y2_team = ifelse(event_year == "FY2016", sum(team_total_gifts), 0),
                                                            y3_team = ifelse(event_year == "FY2017", sum(team_total_gifts), 0))

# Count teams
count <- with(imp_2, aggregate(team_id ~ name, FUN = function(x){length(unique(x))}))

# Combine by event
event_dat1 <- sqldf("select a.*, b.team_id as num_teams from event_dat a join count b on a.name = b.name")

# Summarize demographics
event_demo <- imp_2 %>% group_by(name) %>% summarize(age = mean(medage_cy),
                                                     diversity = mean(divindx_cy),
                                                     house_inc = mean(medhinc_cy),
                                                     disposable_inc = mean(meddi_cy),
                                                     worth = mean(mednw_cy),
                                                     raised = sum(total_gifts))

# Create markers for top grossing
event_demo$y1_top_event <- as.factor(ifelse(event_demo$name %in% y1_top_event$name, 1, 0)) 
event_demo$y2_top_event <- as.factor(ifelse(event_demo$name %in% y2_top_event$name, 1, 0))
event_demo$y3_top_event <- as.factor(ifelse(event_demo$name %in% y3_top_event$name, 1, 0))
event_demo$top_event <- as.factor(ifelse(event_demo$name %in% top_events_total$name, 1, 0))

# Join counts and demographic info
event_dat2 <- sqldf("select a.team_id as num_teams, b.count, c.* from count a join event_summ b on a.name = b.name join event_demo c on a.name = c.name")

# Count participants
seg_dat <- imp_2 %>% group_by(tap_desc) %>% mutate(seg_count = n())

seg_demo <- seg_dat %>% group_by(tap_desc) %>% summarise(age = mean(medage_cy),
                                                         diversity = mean(divindx_cy),
                                                         house_inc = mean(medhinc_cy),
                                                         disposable_inc = mean(meddi_cy),
                                                         worth = mean(mednw_cy))

# Merge
seg_dat1 <- merge(seg_dat[,c("tap_desc", "seg_count")], seg_demo, by = "tap_desc")

seg_dat2 <- distinct(seg_dat1, tap_desc, .keep_all = TRUE)

# Add top_segment marker
seg_dat2$top_seg <- ifelse(seg_dat2$tap_desc %in% top_segments_total$tap_desc, 1, 0)

# End timer
end1 <- toc()



# Reload data
dt <- setDT(read.csv("Data/LuminateDataExport_UTDP2_011818.csv"))

# Data table approach
tic("data.table approach")

# Clean the data

# Remove the unwanted characters
dt1 <- dt[, lapply(.SD, function(x) {gsub(c("\\$| |,"), "", x)})]

# Lower-casing
setnames(dt1, names(dt1), tolower(names(dt1)))[]

important1 <- dt1[,  c("event_date", "city", "company_goal", "company_name", "fundraising_goal", "state", "street", "team_count", "team_member_goal", "team_name", "zip", "gifts_count", "registration_gift") := NULL]

# Convert everything to character
imp_1.1 <- important1[, lapply(.SD, as.character, stringsAsFactors = FALSE)]

# Function to convert numeric columns
conversion <- function(x) {
  
  stopifnot(is.list(x))
  
  x[] <- rapply(x, utils::type.convert, classes = "character", how = "replace", as.is = TRUE)
  
  return(x)
}

# Conversion
imp_2.1 <- conversion(imp_1.1)

# Factor columns
cols <- c("event_year", "name", "participant_id", "team_captain", "team_id", "match_code", "tap_level", "tap_desc")

imp_3.1 <- imp_2.1[, (cols) := lapply(.SD, as.factor), .SDcols = cols]

# count by category
imp_3.1[, ':=' (team_count = .N), by = team_id]
imp_3.1[, ':=' (event_count = .N), by = name]
imp_3.1[, ':=' (segment_count = .N), by = tap_desc]

# sum $ by category
imp_3.1[, ':=' (personal_sum = sum(total_gifts)), by = participant_id]

imp_3.1[, ':=' (segment_sum = sum(total_gifts)), by = tap_desc]

imp_3.1[, ':=' (event_sum = sum(total_gifts)), by = name]

imp_3.1[, ':=' (year_sum = sum(total_gifts)), by = event_year] 

# top 10% 
n <- 10

imp_3.1[, top_walker := as.factor(ifelse(participant_id %in% imp_3.1[personal_sum > quantile(personal_sum, prob = 1 - n/100)]$participant_id, 1, 0))]

imp_3.1[, top_team := as.factor(ifelse(team_id %in% imp_3.1[team_total_gifts > quantile(team_total_gifts, prob = 1 - n/100)]$team_id, 1, 0))]

imp_3.1[, top_segment := as.factor(ifelse(tap_desc %in% imp_3.1[segment_sum > quantile(segment_sum, prob = 1 - n/100)]$tap_desc, 1, 0))]

imp_3.1[, top_event := as.factor(ifelse(name %in% imp_3.1[event_sum > quantile(event_sum, prob = 1 - n/100)]$name, 1, 0))]

# By year
imp_3.1[, y1_top_walker := as.factor(ifelse(event_year == "FY2015" & participant_id %in% imp_3.1[personal_sum > quantile(personal_sum, prob = 1 - n/100)]$participant_id, 1, 0))]
imp_3.1[, y2_top_walker := as.factor(ifelse(event_year == "FY2016" & participant_id %in% imp_3.1[personal_sum > quantile(personal_sum, prob = 1 - n/100)]$participant_id, 1, 0))]
imp_3.1[, y3_top_walker := as.factor(ifelse(event_year == "FY2017" & participant_id %in% imp_3.1[personal_sum > quantile(personal_sum, prob = 1 - n/100)]$participant_id, 1, 0))]

imp_3.1[, y1_top_team := as.factor(ifelse(event_year == "FY2015" & team_id %in% imp_3.1[team_total_gifts > quantile(team_total_gifts, prob = 1 - n/100)]$team_id, 1, 0))]
imp_3.1[, y2_top_team := as.factor(ifelse(event_year == "FY2016" & team_id %in% imp_3.1[team_total_gifts > quantile(team_total_gifts, prob = 1 - n/100)]$team_id, 1, 0))]
imp_3.1[, y3_top_team := as.factor(ifelse(event_year == "FY2017" & team_id %in% imp_3.1[team_total_gifts > quantile(team_total_gifts, prob = 1 - n/100)]$team_id, 1, 0))]

imp_3.1[, y1_top_segment := as.factor(ifelse(event_year == "FY2015" & tap_desc %in% imp_3.1[segment_sum > quantile(segment_sum, prob = 1 - n/100)]$tap_desc, 1, 0))]
imp_3.1[, y2_top_segment := as.factor(ifelse(event_year == "FY2016" & tap_desc %in% imp_3.1[segment_sum > quantile(segment_sum, prob = 1 - n/100)]$tap_desc, 1, 0))]
imp_3.1[, y3_top_segment := as.factor(ifelse(event_year == "FY2017" & tap_desc %in% imp_3.1[segment_sum > quantile(segment_sum, prob = 1 - n/100)]$tap_desc, 1, 0))]

imp_3.1[, y1_top_event := as.factor(ifelse(event_year == "FY2015" & name %in% imp_3.1[event_sum > quantile(event_sum, prob = 1 - n/100)]$name, 1, 0))]
imp_3.1[, y2_top_event := as.factor(ifelse(event_year == "FY2016" & name %in% imp_3.1[event_sum > quantile(event_sum, prob = 1 - n/100)]$name, 1, 0))]
imp_3.1[, y3_top_event := as.factor(ifelse(event_year == "FY2017" & name %in% imp_3.1[event_sum > quantile(event_sum, prob = 1 - n/100)]$name, 1, 0))]


# Create df for RF model of top_walker
walk_dat2 <- imp_3.1[, ltf_gifts := sum(total_gifts), by = participant_id][]

y1_personal <- walk_dat2[(event_year == "FY2015"), list(y1_personal = sum(total_gifts)), by = participant_id]
y2_personal <- walk_dat2[(event_year == "FY2016"), list(y2_personal = sum(total_gifts)), by = participant_id]
y3_personal <- walk_dat2[(event_year == "FY2017"), list(y3_personal = sum(total_gifts)), by = participant_id]

setkey(walk_dat2, participant_id)
setkey(y1_personal, participant_id)
setkey(y2_personal, participant_id)
setkey(y3_personal, participant_id)

walk_dat3 <- merge(walk_dat2, y1_personal, all.x = TRUE)
walk_dat3[is.na(y1_personal), y1_personal := 0]
setkey(walk_dat3, participant_id)

walk_dat3 <- merge(walk_dat3, y2_personal, all.x = TRUE)
walk_dat3[is.na(y2_personal), y2_personal := 0]

walk_dat3 <- merge(walk_dat3, y3_personal, all.x = TRUE)
walk_dat3[is.na(y3_personal), y3_personal := 0]

# Summarize demographics for event RF
event_demo_dt <- walk_dat3[, list(age = mean(medage_cy), diversity = mean(divindx_cy), house_inc = mean(medhinc_cy), disposable_inc = mean(meddi_cy), worth = mean(mednw_cy), raised = sum(total_gifts)), by = "name"]

# Final df for Event model
event_rf_dat <- sqldf("select a.*, b.age, b.diversity, b.house_inc, b.disposable_inc, b.worth, b.raised from walk_dat3 a join event_demo_dt b on a.name = b.name")

# Summarize info for tapestry RF
segments_dt <- walk_dat3[, list(age = mean(medage_cy), diversity = mean(divindx_cy), house_inc = mean(medhinc_cy), disposable_inc = mean(meddi_cy), worth = mean(mednw_cy), raised = sum(total_gifts)), by = "tap_desc"]

# Final df for segment model
segment_rf_dat <- sqldf("select a.*, b.age, b.diversity, b.house_inc, b.disposable_inc, b.worth, b.raised from walk_dat3 a join segments_dt b on a.tap_desc = b.tap_desc")

# End timer
end2 <- toc()
