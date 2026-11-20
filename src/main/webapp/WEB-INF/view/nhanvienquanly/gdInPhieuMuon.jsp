<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="Phiếu mượn tài liệu"/>
<c:set var="catalogView" value="${true}"/>
<c:set var="pageStylesheet" value="/assets/css/gdInPhieuMuon.css"/>
<%@ include file="/WEB-INF/view/dungchung/header.jspf" %>
<c:url var="detailUrl" value="/reports/readers/loans/detail">
    <c:param name="startDate" value="${startDate}"/>
    <c:param name="endDate" value="${endDate}"/>
    <c:param name="readerId" value="${readerId}"/>
    <c:param name="loanId" value="${loan.id}"/>
</c:url>
<div class="print-toolbar">
    <a class="back" href="<c:out value="${detailUrl}"/>">← Quay lại chi tiết lần mượn</a>
    <button id="print-slip" type="button">In phiếu</button>
</div>
<article class="loan-slip" aria-labelledby="slip-title">
    <header class="slip-heading">
        <p class="slip-library">Thư viện Học viện Công nghệ Bưu chính Viễn thông</p>
        <h1 id="slip-title">PHIẾU MƯỢN TÀI LIỆU</h1>
        <p>Mã phiếu <strong><c:out value="${loan.loanNumber}"/></strong></p>
    </header>
    <dl class="slip-fields">
        <div><dt>Mã độc giả</dt><dd><c:out value="${loan.reader.readerCode}"/></dd></div>
        <div><dt>Họ tên độc giả</dt><dd><c:out value="${loan.reader.fullName}"/></dd></div>
        <div><dt>Thời gian mượn</dt><dd><c:out value="${checkoutLabel}"/></dd></div>
        <div><dt>Nhân viên xử lý</dt><dd><c:out value="${loan.processedBy.fullName}"/></dd></div>
    </dl>
    <table class="slip-table">
        <thead>
            <tr>
                <th scope="col">STT</th>
                <th scope="col">Mã bản</th>
                <th scope="col">Tên tài liệu</th>
                <th scope="col">Hạn trả</th>
            </tr>
        </thead>
        <tbody>
            <c:forEach var="detail" items="${loan.loanDetails}" varStatus="line">
                <c:set var="doc" value="${documentsByItemId[detail.item.id]}"/>
                <tr>
                    <td>${line.count}</td>
                    <td class="code"><c:out value="${detail.item.itemCode}"/></td>
                    <td><c:out value="${doc.title}"/></td>
                    <td><c:out value="${detailDueDates[detail.id]}"/></td>
                </tr>
            </c:forEach>
        </tbody>
    </table>
    <p class="slip-total">Tổng số bản tài liệu <strong><c:out value="${loan.loanDetails.size()}"/></strong></p>
    <div class="signatures">
        <div><strong>Người mượn</strong><span>Ký và ghi rõ họ tên</span></div>
        <div><strong>Nhân viên thư viện</strong><span>Ký và ghi rõ họ tên</span></div>
    </div>
</article>
<script src="<c:url value='/assets/print-slip.js'/>" defer></script>
<%@ include file="/WEB-INF/view/dungchung/footer.jspf" %>
