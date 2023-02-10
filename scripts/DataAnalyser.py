from unicodedata import numeric
import pandas as pd
from pandas.api.types import is_numeric_dtype
import os
import seaborn as sns
import re
import numpy as np
import matplotlib.pyplot as plt
from datetime import date
import datetime as dt

rocket = sns.color_palette("flare", 4)
figsize=(20,10)

transformed_folder=(os.path.realpath(os.path.dirname(__file__)))+"/../transformed_data/"
daily_graphs_folder=(os.path.realpath(os.path.dirname(__file__)))+"/../reporting_document/graphs/daily/"
weekly_graphs_folder=(os.path.realpath(os.path.dirname(__file__)))+"/../reporting_document/graphs/weekly/"

def data_cleaning(df):
        df["name"] = df['firstname'] + " " + df['lastname']
        df["name"] = df.name.str.replace('\W','')

        df["datetime"] = pd.to_datetime(df['date'], format='%Y%m%d-%H%M%S').dt.strftime('%Y-%m-%d')
        df['distance'] = df['distance'] / 1000
        df['moving_time'] = df['moving_time'] / 60
        df['elapsed_time'] = df['elapsed_time'] /60 
        df["speed"] = df["distance"] / df["moving_time"] * 75
        
        df["workout_type"] = df["workout_type"].astype("category")
        df["sport_type"] = df["sport_type"].astype("category")
        df["club"] = df["club"].astype("category")

        df = df.drop(['firstname', 'lastname', 'date'], axis=1)
        df = df.drop_duplicates()

        """REMOVE ALL EXAGGERATED DATA"""
        for key in df.select_dtypes(include=np.number).columns.tolist():
                max = df[key].mean() + (df[key].std() * 3)
                min = df[key].mean() - (df[key].std() * 3)
                df = df[(df[key] > min) & (df[key] < max) & (df[key] != 0)]
                df[key] = df[key].round(2)
        return df

def ultimate_club_acts_df():
        ultimate = pd.DataFrame()
        appended_data=[]
        for file in os.listdir(transformed_folder):
            if 'activities' in file:
                df = pd.read_csv(transformed_folder+file)
                df['club'] = str(file).split('_')[0]
                appended_data.append(df)
        ultimate = pd.concat(appended_data)        
        return ultimate

def get_today(df):
    range_max = df.datetime.max()
    df = df[(df['datetime'] == range_max)]
    df['datetime'] = pd.to_datetime(df["datetime"], format="%Y-%m-%d").dt.strftime('%Y-%m-%d')
    return df

def get_last_week_df(df):
    import datetime as dt
    range_max = pd.to_datetime(df['datetime'].max(), format="%Y-%m-%d")
    range_min = range_max - dt.timedelta(days=7)
    df['datetime'] = pd.to_datetime(df["datetime"], format="%Y-%m-%d")
    df = df[(df['datetime'] <= range_max) & (df['datetime'] >= range_min)]
    return df

df_act = ultimate_club_acts_df()
df_act = data_cleaning(df_act)
today_act = get_today(df_act)

numerical_columns = df_act.select_dtypes(include=np.number).columns.tolist()

def daily_jointplot(df):
    f, ax = plt.subplots(figsize=figsize)
    fig = sns.jointplot(data=df, x='speed', y='moving_time', kind='hex', color="#FFD580", ax=ax)
    fig.savefig(daily_graphs_folder+"regular_jointplot.png", bbox_inches="tight")


def daily_durable_goat(df):
    fig = sns.jointplot(data=get_today(df), x="total_elevation_gain", y="moving_time", color="brown")
    fig.plot_joint(sns.kdeplot, color="orange", zorder=0, levels=6)
    fig.plot_marginals(sns.rugplot, color="orange", height=-.15, clip_on=False)
    fig.savefig(daily_graphs_folder+"regular_durablegoat.png", bbox_inches="tight")

def daily_speed_goat(df):
    fig = sns.jointplot(data=get_today(df), x="speed", y="moving_time", color="brown")
    fig.plot_joint(sns.kdeplot, color="orange", zorder=0, levels=6)
    fig.plot_marginals(sns.rugplot, color="orange", height=-.15, clip_on=False)
    fig.savefig(daily_graphs_folder+"regular_speedgoat.png", bbox_inches="tight")

def daily_scatter(df):
    f, ax = plt.subplots(figsize=figsize)
    fig = sns.countplot(data=df, x="sport_type", hue="club", ax=ax)
    fig.get_figure().savefig(daily_graphs_folder+"regular_workoutplot.png")

def daily_leaderboard(df):
    for key in numerical_columns:
        f, ax = plt.subplots(figsize=(10,10), dpi=100)
        leaderboard = df.loc[:, ['name', key, 'club']].sort_values(by=[key], ascending=False).head(10)
        sns.histplot(data=df, x=key, hue='club', multiple='stack', bins=10, palette=rocket)
        table = plt.table(cellText=leaderboard.values, colLabels=leaderboard.columns, loc='bottom', transform=plt.gcf().transFigure, bbox=(0, -0.5, 1, 0.5))
        table.auto_set_font_size(False)
        table.set_fontsize(12)
        fig = plt.gcf()
        fig.canvas.draw()
        fig.savefig(daily_graphs_folder+"leaderboard_"+key+".png", bbox_inches="tight")

def week_report_act_per_date(df):
    counts = get_last_week_df(df)
    f, ax = plt.subplots(figsize=figsize)
    fig = sns.countplot(ax=ax, x=counts['datetime'], hue=counts['club'], palette=rocket)
    fig.set(xlabel='Date', ylabel='Number of activities')
    fig.set_xticklabels(['Ma','Di','Wo','Do','Vr','Za','Zo'])
    fig.get_figure().savefig(weekly_graphs_folder+"week_report_count_per_date.png")

def week_report_distance_vs_number(df):
    f, axs = plt.subplots(1, 2, figsize=figsize, gridspec_kw=dict(width_ratios=[1,1]))
    fig = sns.scatterplot(data=df, x="distance", y="moving_time", hue="club", ax=axs[0], palette=rocket)
    fig.set(xlabel='Distance in KM', ylabel='Time in Minutes')
    fig = sns.histplot(data=df, x="club", hue="club", shrink=.8, alpha=.8, legend=False, ax=axs[1], bins=10, palette=rocket)
    fig.set(xlabel='Number of activities', ylabel='Number of people')
    f.tight_layout()
    fig.get_figure().savefig(weekly_graphs_folder+"week_report_distance_v_number.png")

def week_report_speed_hist(df):
    f, ax = plt.subplots(figsize=figsize)
    fig = sns.histplot(ax=ax, data=df, x=df["speed"],  hue=df["club"], multiple="stack", palette=rocket)
    fig.get_figure().savefig(weekly_graphs_folder+"week_report_speed_hist.png")

def is_sunday():
    if date.today().weekday() == 6:
        return True
    else:
        return False

def get_change_members():
    ultimate = pd.DataFrame()
    appended_data=[]
    for file in os.listdir(transformed_folder):
        if 'info' in file:
            df = pd.read_csv(transformed_folder+file)
            df['club'] = str(file).split('_')[0]
            df["datetime"] = pd.to_datetime(df['date'], format='%Y%m%d-%H%M%S')
            df["datetime"] = df['datetime'].dt.strftime("%Y-%m-%d")
            df["datetime"] = pd.to_datetime(df['datetime'], format="%Y-%m-%d")
            df['previous'] = df['member_count'].shift(1, fill_value=df['member_count'].min())
            df['change'] = df['member_count'] - df['previous']
            appended_data.append(df)

    ultimate = pd.concat(appended_data)        
    return ultimate



def week_report_sport_types(df):
    n = len(df.select_dtypes(include=np.number).columns.tolist())
    eq = n//2
    rest = n%2
    n = (eq) + (rest)
    f, axs = plt.subplots(n, 2, figsize=(20, 20), gridspec_kw=dict(width_ratios=[4, 4]))
    teller=0
    for key in df.select_dtypes(include=np.number).columns.tolist():
        x=teller%2
        y=teller//2
        fig = sns.stripplot(ax=axs[y][x], data=df, x='sport_type', y=key, hue='club', palette=rocket)
        fig.set(xlabel='Type', ylabel=key)
        teller += 1

    if rest == 1:
        axs[eq,rest].set_axis_off()

    fig.get_figure().savefig(weekly_graphs_folder+"week_report_sport_types.png")

df = ultimate_club_acts_df()
df = data_cleaning(df)

"""
GENERATE CLUB CHANGE REPORT
"""
if is_sunday():
    df_weekly = get_change_members()
    fig = sns.lineplot(data=df_weekly, x='datetime', y='change', hue='club', palette=rocket)
    fig.set_xticklabels(['Ma','Di','Wo','Do','Vr','Za','Zo'])
    fig.get_figure().savefig(weekly_graphs_folder+"week_change_members.png")

"""
GENERATE DAILY REPORTS
HAPPENS EVERY DAY
"""

daily_jointplot(today_act)
daily_leaderboard(today_act)
daily_speed_goat(today_act)
daily_durable_goat(today_act)



"""
GENERATE WEEKLY REPORTS
HAPPENS ONLY ON SUNDAY
"""
if is_sunday():    
    df_weekly = get_last_week_df(df)
    week_report_speed_hist(df_weekly)
    week_report_sport_types(df_weekly)
    week_report_distance_vs_number(df_weekly)
    week_report_act_per_date(df_weekly)