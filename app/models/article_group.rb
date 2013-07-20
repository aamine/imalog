class ArticleGroup < ActiveRecord::Base
  self.table_name = 'articles'

  def ArticleGroup.timeline
    find_by_sql('
      select
        cast(extract(year from created_at) * 100
          + extract(month from created_at) as integer) as group_id
        , count(*) as article_count
      from articles
      group by group_id
      order by group_id desc
    '.strip.gsub(/\s+/, ' '))
  end

  def display_name
    y = group_id / 100
    m = group_id % 100
    sprintf('%04d-%02d (%d)', y, m, article_count)
  end
end
