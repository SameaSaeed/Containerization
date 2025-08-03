from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *
import sys

def main():
    # Create Spark session with more configuration
    spark = SparkSession.builder \
        .appName("DataAnalytics") \
        .config("spark.sql.adaptive.enabled", "true") \
        .config("spark.sql.adaptive.coalescePartitions.enabled", "true") \
        .getOrCreate()
    
    # Create sample sales data
    sales_data = [
        ("2023-01-01", "Electronics", "Laptop", 1200.00, 2),
        ("2023-01-02", "Electronics", "Phone", 800.00, 3),
        ("2023-01-03", "Clothing", "Shirt", 50.00, 5),
        ("2023-01-04", "Electronics", "Tablet", 400.00, 1),
        ("2023-01-05", "Clothing", "Pants", 80.00, 2),
        ("2023-01-06", "Electronics", "Laptop", 1200.00, 1),
        ("2023-01-07", "Books", "Novel", 15.00, 10),
        ("2023-01-08", "Books", "Textbook", 120.00, 3),
        ("2023-01-09", "Clothing", "Jacket", 150.00, 1),
        ("2023-01-10", "Electronics", "Phone", 800.00, 2)
    ]
    
    # Define schema
    schema = StructType([
        StructField("date", StringType(), True),
        StructField("category", StringType(), True),
        StructField("product", StringType(), True),
        StructField("price", DoubleType(), True),
        StructField("quantity", IntegerType(), True)
    ])
    
    # Create DataFrame
    df = spark.createDataFrame(sales_data, schema)
    
    # Convert date string to date type
    df = df.withColumn("date", to_date(col("date"), "yyyy-MM-dd"))
    df = df.withColumn("total_sales", col("price") * col("quantity"))
    
    print("=== Sales Data Analysis ===")
    df.show()
    
    # Analysis 1: Total sales by category
    print("\n=== Total Sales by Category ===")
    category_sales = df.groupBy("category") \
        .agg(sum("total_sales").alias("total_revenue"),
             sum("quantity").alias("total_quantity")) \
        .orderBy(desc("total_revenue"))
    category_sales.show()
    
    # Analysis 2: Top selling products
    print("\n=== Top Selling Products ===")
    product_sales = df.groupBy("product") \
        .agg(sum("total_sales").alias("total_revenue"),
             sum("quantity").alias("total_quantity")) \
        .orderBy(desc("total_revenue"))
    product_sales.show()
    
    # Analysis 3: Daily sales trend
    print("\n=== Daily Sales Trend ===")
    daily_sales = df.groupBy("date") \
        .agg(sum("total_sales").alias("daily_revenue")) \
        .orderBy("date")
    daily_sales.show()
    
    # Save results to persistent storage
    category_sales.coalesce(1).write.mode("overwrite").csv("/data/category_sales")
    product_sales.coalesce(1).write.mode("overwrite").csv("/data/product_sales")
    
    print("\n=== Analysis Complete - Results saved to /data/ ===")
    
    spark.stop()

if __name__ == "__main__":
    main()