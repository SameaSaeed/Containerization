from pyspark.sql import SparkSession
import sys

def main():
    # Create Spark session
    spark = SparkSession.builder \
        .appName("WordCount") \
        .getOrCreate()
    
    # Read input file
    input_file = sys.argv[1] if len(sys.argv) > 1 else "/data/sample.txt"
    
    # Read text file and count words
    text_file = spark.read.text(input_file)
    
    # Split lines into words and count
    from pyspark.sql.functions import split, explode, lower, col
    
    words = text_file.select(
        explode(split(lower(col("value")), " ")).alias("word")
    ).filter(col("word") != "")
    
    word_counts = words.groupBy("word").count().orderBy("count", ascending=False)
    
    # Show results
    print("Word Count Results:")
    word_counts.show()
    
    # Stop Spark session
    spark.stop()

if __name__ == "__main__":
    main()