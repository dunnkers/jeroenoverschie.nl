import urllib.parse
import feedparser
import xmltodict
import urllib.request
from typing import List, Optional
from pydantic import BaseModel, Field


class Author(BaseModel):
    id: int
    name: str
    role: Optional[str] = None
    image_url: Optional[str] = None
    small_image_url: Optional[str] = None
    link: Optional[str] = None
    average_rating: Optional[float] = None
    ratings_count: Optional[int] = None
    text_reviews_count: Optional[int] = None

    model_config = {"extra": "allow"}


class Book(BaseModel):
    id: int = Field(..., alias="id")
    isbn: Optional[str] = None
    isbn13: Optional[str] = None
    text_reviews_count: Optional[int] = None
    uri: Optional[str] = None
    title: str
    title_without_series: str
    image_url: Optional[str] = None
    small_image_url: Optional[str] = None
    large_image_url: Optional[str] = None
    link: Optional[str] = None
    num_pages: Optional[int] = None
    format: Optional[str] = None
    edition_information: Optional[str] = None
    publisher: Optional[str] = None
    publication_day: Optional[int] = None
    publication_year: Optional[int] = None
    publication_month: Optional[int] = None
    average_rating: Optional[float] = None
    ratings_count: Optional[int] = None
    description: Optional[str] = None
    authors: List[Author]
    published: Optional[str] = None
    work: Optional[dict] = None  # Simplified

    model_config = {"extra": "allow"}


class Shelf(BaseModel):
    id: int = Field(..., alias="id")
    name: str = Field(..., alias="name")
    review_shelf_id: int = Field(..., alias="review_shelf_id")
    exclusive: bool = Field(..., alias="exclusive")
    sortable: bool = Field(..., alias="sortable")


    model_config = {"extra": "allow"}




class Review(BaseModel):
    id: int
    book: Book
    rating: int
    votes: int
    spoiler_flag: bool
    spoilers_state: str
    shelves: List[Shelf]
    started_at: Optional[str] = None
    read_at: Optional[str] = None
    date_added: str
    date_updated: str
    read_count: int
    body: str
    comments_count: int
    url: Optional[str] = None
    link: Optional[str] = None
    owned: int

    model_config = {"extra": "allow"}


class Request(BaseModel):
    authentication: bool
    key: str
    method: str

    model_config = {"extra": "allow"}



class Reviews(BaseModel):
    start: int
    end: int
    total: int
    review: List[Review]

    model_config = {"extra": "allow"}



class GoodreadsResponse(BaseModel):
    Request: Request
    reviews: Reviews

    model_config = {"extra": "allow"}

class GoodreadsAPIResponse(BaseModel):
    GoodreadsResponse: GoodreadsResponse
    


def fetch_shelf(user_id: str, shelf_name: str, key: str):
    # construct URL
    url = f"https://www.goodreads.com/review/list/{user_id}.xml"
    params = {
        "v": 2,
        "shelf": shelf_name,
        "key": key,
    }
    params_str = urllib.parse.urlencode(params)
    url = f"{url}?{params_str}"

    # call API
    response_xml = urllib.request.urlopen(url).read()
    response_dict = xmltodict.parse(response_xml)
    response_model = GoodreadsAPIResponse.model_validate(response_dict)

    # parse XML




def fetch_quotes(user_id: str):
    quotefeed = feedparser.parse(f"https://www.goodreads.com/quotes/list_rss/{user_id}")
