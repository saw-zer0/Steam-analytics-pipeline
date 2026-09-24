-- Optimal price points by genre.
-- The sweet spot is the price band with the largest share of games in each genre.
with priced_games as (
	select distinct
		metrics.game_sk,
		genres.genre_name,
		metrics.price
	from dbt_mart.fct_game_metrics as metrics
	join dbt_mart.bridge_game_genre as game_genres
		on metrics.game_sk = game_genres.game_sk
	join dbt_mart.dim_genre as genres
		on game_genres.genre_sk = genres.genre_sk
	where metrics.price is not null
	  and metrics.price >= 0
),
price_bands as (
	select
		game_sk,
		genre_name,
		price,
		case
			when price = 0 then 'Free'
			when price < 5 then '$0.01-$4.99'
			when price < 10 then '$5.00-$9.99'
			when price < 15 then '$10.00-$14.99'
			when price < 20 then '$15.00-$19.99'
			when price < 30 then '$20.00-$29.99'
			when price < 50 then '$30.00-$49.99'
			else '$50.00+'
		end as price_band,
		case
			when price = 0 then 0
			when price < 5 then 1
			when price < 10 then 2
			when price < 15 then 3
			when price < 20 then 4
			when price < 30 then 5
			when price < 50 then 6
			else 7
		end as price_band_order
	from priced_games
),
genre_totals as (
	select
		genre_name,
		count(*) as games_in_genre,
		percentile_cont(0.25) within group (order by price) as price_25th_percentile,
		percentile_cont(0.50) within group (order by price) as median_price,
		percentile_cont(0.75) within group (order by price) as price_75th_percentile,
		avg(price) as average_price
	from price_bands
	group by genre_name
),
band_distribution as (
	select
		genre_name,
		price_band,
		price_band_order,
		count(*) as games_in_band,
		count(*)::numeric / sum(count(*)) over (partition by genre_name) as share_of_genre
	from price_bands
	group by genre_name, price_band, price_band_order
),
ranked_bands as (
	select
		distribution.*,
		row_number() over (
			partition by genre_name
			order by games_in_band desc, price_band_order
		) as band_rank
	from band_distribution as distribution
)
select
	totals.genre_name,
	totals.games_in_genre,
	round(totals.average_price, 2) as average_price,
	round(totals.price_25th_percentile::numeric, 2) as price_25th_percentile,
	round(totals.median_price::numeric, 2) as median_price,
	round(totals.price_75th_percentile::numeric, 2) as price_75th_percentile,
	sweet_spot.price_band as sweet_spot_price_band,
	round(sweet_spot.share_of_genre * 100, 2) as sweet_spot_share_percent,
	sweet_spot.games_in_band as games_in_sweet_spot_band,
	distribution.price_band,
	distribution.games_in_band,
	round(distribution.share_of_genre * 100, 2) as price_band_share_percent
from genre_totals as totals
join ranked_bands as sweet_spot
	on totals.genre_name = sweet_spot.genre_name
   and sweet_spot.band_rank = 1
join ranked_bands as distribution
	on totals.genre_name = distribution.genre_name
order by totals.genre_name, distribution.price_band_order;
