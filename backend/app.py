import os

import pymysql
from flask import Flask

app = Flask(__name__)


def read_secret(path):
    with open(path, "r", encoding="utf-8") as secret_file:
        return secret_file.read().strip()



@app.route("/health")
def health():
    return {"status": "healthy"}


@app.route("/api/hello")
def hello():
    return {"message": "Hello from the DevOps backend!"}


@app.route("/api/db-test")
def db_test():
    connection = pymysql.connect(
        host=os.environ["DB_HOST"],
        user=os.environ["DB_USER"],
        password=read_secret("/run/secrets/mysql_password"),
        database=os.environ["DB_NAME"],
        port=int(os.environ.get("DB_PORT", "3306")),
    )

    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            result = cursor.fetchone()

        return {"database": "connected", "result": result[0]}
    finally:
        connection.close()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
