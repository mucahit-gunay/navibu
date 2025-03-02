class Config:
    SECRET_KEY = 'supersecretkey'
    SQLALCHEMY_DATABASE_URI = "mysql+pymysql://root:Navibu161308_@localhost/NavibuDB"
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    MAIL_SERVER = 'smtp.gmail.com'
    MAIL_PORT = 587
    MAIL_USERNAME = 'navibu0@gmail.com'
    MAIL_PASSWORD = 'lypi zsny krrp wihq'
    MAIL_USE_TLS = True
    MAIL_USE_SSL = False
    MAIL_DEFAULT_SENDER = 'navibu0@gmail.com'

    MYSQL_HOST = 'localhost'
    MYSQL_USER = 'root'
    MYSQL_PASSWORD = 'Navibu161308_'
    MYSQL_DB = 'navibuDB'