<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="Không thể mở trang"/>
<c:set var="pageStylesheet" value="/assets/css/gdLoi.css"/>
<%@ include file="/WEB-INF/view/dungchung/header.jspf" %>
<h1>Không thể mở trang</h1>
<c:if test="${not empty error}"><p class="notice error" role="alert"><c:out value="${error}"/></p></c:if>
<c:if test="${sessionScope.account.role eq 'MANAGER'}">
    <c:url var="reportUrl" value="/reports/readers">
        <c:param name="startDate" value="${startDate}"/>
        <c:param name="endDate" value="${endDate}"/>
    </c:url>
    <a class="back" href="<c:out value="${reportUrl}"/>">← Quay về thống kê độc giả</a>
</c:if>
<c:if test="${sessionScope.account.role eq 'READER'}">
    <a class="back" href="<c:url value='/documents'/>">← Quay về tìm tài liệu</a>
</c:if>
<c:if test="${empty sessionScope.account}">
    <a class="back" href="<c:url value='/'/>">← Về trang đăng nhập</a>
</c:if>
<%@ include file="/WEB-INF/view/dungchung/footer.jspf" %>
