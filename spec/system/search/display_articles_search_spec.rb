require "rails_helper"

RSpec.describe "Display articles search spec", type: :system, js: true, elasticsearch: "FeedContent" do
  let(:found_article_one) { create(:article) }
  let(:found_article_two) { create(:article) }
  let(:not_found_article) { create(:article) }

  before do
    stub_request(:post, "http://www.google-analytics.com/collect")
  end

  it "returns correct results for a search" do
    found_article_one.tags << create(:tag, name: "ruby")
    allow(found_article_two).to receive(:body_text).and_return("Ruby Tuesday")
    allow(not_found_article).to receive(:body_text).and_return("Python All Day Long")
    articles = [found_article_one, found_article_two, not_found_article]
    index_documents_for_search_class(articles, Search::FeedContent)
    visit "/search?q=ruby&filters=class_name:Article"

    expect(page).to have_content(found_article_one.title)
    expect(page).to have_content(found_article_two.title)
    expect(page).not_to have_content(not_found_article.title)
  end

  it "returns all expected article fields" do
    allow(found_article_one).to receive(:reading_time).and_return(5)
    allow(found_article_one).to receive(:comments_count).and_return(2)
    found_article_one.tags << create(:tag, name: "ruby")
    index_documents_for_search_class([found_article_one], Search::FeedContent)
    visit "/search?q=ruby&filters=class_name:Article"

    expect(page).to have_content(found_article_one.title)
    expect(find("#article-link-#{found_article_one.id}")["href"]).to include(found_article_one.path)
    expect(find_button("SAVE")["data-reactable-id"].to_i).to eq(found_article_one.id)
    expect(find_link("5 min read")).to be_present
    expect(find_link("#ruby")["href"]).to include("/t/ruby")
    expect(find_link(found_article_one.user.name)["href"]).to include(found_article_one.username)
    expect(find(".engagement-count-number").text.to_i).to eq(2)
  end
end
