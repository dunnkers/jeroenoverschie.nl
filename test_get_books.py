import os
from dotenv import load_dotenv
from get_books import fetch_shelf


def test_fetch_shelf():
    load_dotenv()
    books = fetch_shelf(
        user_id=os.environ["GOODREADS_USER_ID"],
        shelf_name="read",
        key=os.environ["GOODREADS_API_KEY"],
    )
    assert len(books) > 0