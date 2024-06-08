import os

def count_lines_in_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        return sum(1 for line in file)

def count_lines_in_directory(directory):
    total_lines = 0
    file_line_counts = {}
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.v'):
                file_path = os.path.join(root, file)
                line_count = count_lines_in_file(file_path)
                file_line_counts[file_path] = line_count
                total_lines += line_count
                
    return total_lines, file_line_counts

def print_line_counts(total_lines, file_line_counts):
    print(f"Total lines of code: {total_lines}")
    for file_path, line_count in file_line_counts.items():
        print(f"{file_path}: {line_count} lines")

if __name__ == "__main__":
    directory = input("Enter the directory path: ")
    total_lines, file_line_counts = count_lines_in_directory(directory)
    print_line_counts(total_lines, file_line_counts)
